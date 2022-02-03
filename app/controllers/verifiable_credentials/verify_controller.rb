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

    if !@user_id || !@resource_id || !@resource_type
      render status: 400, json: { errors: 'Invalid identifiers' }
    end

    user = User.find_by(id: @user_id)

    if !user
      render status: 400, json: { errors: 'Unknown user' }
    end

    if @resource_type == 'group'
      resource = Group.find_by(id: @resource_id)
    end

    if !resource
      render status: 400, json: { errors: 'Unknown resource' }
    end

    handler = VerifiableCredentials::Verify.new(
      user: user,
      resource: resource,
      resource_type: @resource_type,
      type: 'mattr'
    )

    result = handler.perform(@data)

    if result.success?

      if @resource_type == 'group'
        resource.add(user)
      end

      redirect_url = resource.custom_fields['verifiable_credentials_redirect']
      redirect_url = resource.url if !redirect_url && resource.respond_to(:url)

      MessageBus.publish("/vc/verified", redirect_url, user_ids: [user.id])
    end
  end

  protected

  def setup_provider
    provider = SiteSetting.verifiable_credentials_provider
    send("setup_#{provider}")
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
end
