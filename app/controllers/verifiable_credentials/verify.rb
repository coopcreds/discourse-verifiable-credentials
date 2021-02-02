class ::VerifiableCredentials::VerifyController < ::ApplicationController
  def perform    
    result = verifier.perform(params[:presentation],
      resource: params[:resource],
      resource_id: params[:resource_id]
    )
    
    if result.success?
      render json: success_json
    else
      render json: failed_json
    end
  end
  
  def verifier
    VerifiableCredentials::Verifier.new(
      user: current_user,
      type: :vc_ltd ## can be changed to change verifier
    )
  end
end