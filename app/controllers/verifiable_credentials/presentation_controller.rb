# frozen_string_literal: true

class ::VerifiableCredentials::PresentationController < ::ApplicationController
  def create_request
    resource_type = params[:resource_type]
    resource_id = params[:resource_id]
    type = params[:type]

    if resource_type == 'group'
      resource = Group.find_by(id: resource_id)
    end

    handler = VerifiableCredentials::Verify.new(
      user: current_user,
      type: type,
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
end
