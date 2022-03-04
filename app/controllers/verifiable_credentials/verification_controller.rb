# frozen_string_literal: true

class ::VerifiableCredentials::VerificationController < ::ApplicationController
  layout 'no_ember'
  prepend_view_path(Rails.root.join('plugins', 'discourse-verifiable-credentials', 'app', 'views'))

  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token

  ## Necessary due to the parameters sent by vcltd
  def process_action(*args)
    super
  rescue ActionDispatch::Http::Parameters::ParseError => exception
    if request.body && request.body.respond_to?(:string)
      @jwt = request.body.string
      perform
    else
      render_error(exception.message)
    end
  end

  def verify
    setup_provider or return
    setup_handler or return
    process_credential or return

    MessageBus.publish("/vc/verification-complete", @redirect_url, user_ids: [@user.id])

    render json: success_json
  end

  def verify_oidc
    setup_oidc_provider or return
    setup_handler or return
    process_credential(oidc: true) or return

    if @redirect_url
      if %w(http https).any? { |p| @redirect_url.include?(p) }
        redirect_to @redirect_url
      else
        redirect_to path(@redirect_url)
      end
    else
      redirect_to "/"
    end
  end

  protected

  def process_credential(oidc: false)
    result = @handler.perform(@data, oidc: oidc)
    @redirect_url = result.redirect_url

    true
  end

  def setup_handler
    if !@user.present? || !@resources.present?
      render_error('Invalid identifiers') and return
    end

    @handler = VerifiableCredentials::Handler.new(
      user: @user,
      resources: @resources,
      provider: @provider
    )

    true
  end

  def setup_provider
    @provider = params[:provider]
    send("setup_#{@provider}") or return

    true
  end

  def setup_oidc_provider
    @provider = params[:provider]
    send("setup_#{@provider}_oidc") or return

    true
  end

  def setup_verifiable_credentials_ltd
    token = JWT.decode @jwt, nil, false
    presentation = token.first['vp']
    @data = @jwt

    @user_id = presentation['authnCreds']['user_id']
    @resources = presentation['authnCreds']['resources']
  end

  def setup_mattr
    @data = params.permit(:presentationType, :challengeId, :verified, :holder, claims: {}).to_h

    build_objects_from_mattr_state(@data[:challengeId]) or return

    unless @user.present? && @resources.present?
      render_error('Invalid State') and return
    end

    true
  end

  def setup_mattr_oidc
    code = params[:code]
    @data = { code: code }

    build_objects_from_mattr_state(params[:state]) or return

    unless @user.present? && @resources.present?
      render_error('Invalid State') and return
    end

    true
  end

  def build_objects_from_mattr_state(state)
    parts = state.split('~~')

    unless parts.length > 1 && parts.second.present?
      render_error('Invalid State') and return
    end

    user_id = parts.first.to_i
    @user = User.find_by(id: user_id)

    if !@user
      render_error('Unknown User') and return
    end

    resources = VerifiableCredentials::Resource.split(parts.second)
    unless resources.present?
      render_error('Invalid State') and return
    end

    @resources = VerifiableCredentials::Resource.find_all(resources)

    if !@resources.present?
      render_error('Unknown Resources') and return
    else
      true
    end
  end

  protected

  def render_error(error)
    render 'error', locals: { hide_auth_buttons: true, error: error } and return true
  end
end
