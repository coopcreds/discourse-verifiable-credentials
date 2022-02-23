# frozen_string_literal: true

class ::VerifiableCredentials::PresentationController < ::ApplicationController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token, only: [:initiate]

  def create
    resource_type = params[:resource_type]
    resource_id = params[:resource_id]
    provider = params[:provider]

    if resource_type == 'group'
      resource = Group.find_by(id: resource_id)
    end

    handler = VerifiableCredentials::Verify.new(
      user: current_user,
      provider: provider,
      resource: resource,
      resource_type: resource_type
    )

    jws = handler.create_presentation_request

    if jws
      render json: success_json.merge(jws: jws)
    else
      render json: failed_json
    end
  end

  def initiate
    resource_type = params[:resource_type]
    resource_id = params[:resource_id]
    provider = params[:provider]

    if resource_type == 'group'
      resource = Group.find_by(id: resource_id)
    end

    handler = VerifiableCredentials::Verify.new(
      user: current_user,
      provider: provider,
      resource: resource,
      resource_type: resource_type
    )

    redirect_url = handler.presentation_request_uri

    if redirect_url
      redirect_to redirect_url
    else
      render plain: "[\"Verifiable Credentials Config Error: Redirect\"]", status: 403
    end
  end
end
