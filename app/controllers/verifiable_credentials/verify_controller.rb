# frozen_string_literal: true

class ::VerifiableCredentials::VerifyController < ::ApplicationController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token

  ## Necessary due to the parameters sent by vcltd
  def process_action(*args)
    super
  rescue ActionDispatch::Http::Parameters::ParseError => exception
    if request.body && request.body.respond_to?(:string)
      @jwt = request.body.string
      perform
    else
      render status: 400, json: { errors: [ exception.message ] }
    end
  end

  def verify
    setup_provider
    setup_handler
    process_credential

    if @redirect_url
      MessageBus.publish("/vc/verification-complete", @redirect_url, user_ids: [@user.id])
    end
  end

  def verify_oidc
    setup_oidc_provider
    setup_handler
    process_credential(oidc: true)

    if %w(http https).any? { |p| @redirect_url.include?(p) }
      redirect_to @redirect_url
    else
      redirect_to path(@redirect_url)
    end
  end

  protected

  def process_credential(oidc: false)
    result = @handler.perform(@data, oidc: oidc)
    @redirect_url = nil

    if result.success?
      if @resource_type == 'group'
        @resource.add(@user)
      end

      @redirect_url = @resource.custom_fields['verifiable_credentials_redirect'] || "/"
    else
      if @resource_type == 'group'
        @redirect_url = "/g/#{@resource.name}?failed_to_verify=true"
      end
    end
  end

  def setup_handler
    if !@user_id || !@resource_id || !@resource_type
      render status: 400, json: { errors: 'Invalid identifiers' }
    end

    @user = User.find_by(id: @user_id)

    if !@user
      render status: 400, json: { errors: 'Unknown user' }
    end

    if @resource_type == 'group'
      @resource = Group.find_by(id: @resource_id)
    end

    if !@resource
      render status: 400, json: { errors: 'Unknown resource' }
    end

    @handler = VerifiableCredentials::Verify.new(
      user: @user,
      resource: @resource,
      resource_type: @resource_type,
      provider: @provider
    )
  end

  def setup_provider
    @provider = params[:provider]
    send("setup_#{@provider}")
  end

  def setup_oidc_provider
    @provider = params[:provider]
    send("setup_#{@provider}_oidc")
  end

  def setup_verifiable_credentials_ltd
    token = JWT.decode @jwt, nil, false
    presentation = token.first['vp']
    @data = @jwt

    @user_id = presentation['authnCreds']['user_id']
    @resource_id = presentation['authnCreds']['resource_id']
    @resource_type = presentation['authnCreds']['resource_type']
  end

  def setup_mattr
    @data = params.permit(:presentationType, :challengeId, :verified, :holder, claims: {})

    challenge = @data[:challengeId].split(':')

    if challenge.length != 3
      render status: 400, json: { errors: 'Invalid challenge' }
    end

    @resource_type = challenge.first
    @resource_id = challenge.second.to_i
    @user_id = challenge.last.to_i
  end

  def setup_mattr_oidc
    code = params[:code]
    state = params[:state].split(':')

    if state.length != 3
      render status: 400, json: { errors: 'Invalid state' }
    end

    @data = { code: code }
    @resource_type = state.first
    @resource_id = state.second.to_i
    @user_id = state.last.to_i
  end
end
