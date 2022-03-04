# frozen_string_literal: true

class ::VerifiableCredentials::PresentationController < ::ApplicationController
  requires_login

  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token, only: [:initiate]

  def create
    handler = VerifiableCredentials::Handler.new(
      user: current_user,
      provider: params[:provider],
      resources: resources
    )

    jws = handler.create_presentation_request

    if jws
      render json: success_json.merge(jws: jws)
    else
      render json: failed_json
    end
  end

  def initiate
    handler = VerifiableCredentials::Handler.new(
      user: current_user,
      provider: params[:provider],
      resources: resources,
    )

    redirect_url = handler.presentation_request_uri

    if redirect_url
      redirect_to redirect_url
    else
      render plain: "[\"Verifiable Credentials Config Error: Redirect\"]", status: 403
    end
  end

  def resources
    items = params.permit(:resources)
    return [] unless items[:resources].present?

    resource_list = VerifiableCredentials::Resource.split(items[:resources])
    return [] unless resource_list.present?

    VerifiableCredentials::Resource.find_all(resource_list)
  end
end
