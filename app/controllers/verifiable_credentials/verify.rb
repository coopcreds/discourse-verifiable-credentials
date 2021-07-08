class ::VerifiableCredentials::VerifyController < ::ApplicationController
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

  def perform
    token = JWT.decode @jwt, nil, false
    presentation = token.first['vp']

    user_id = presentation['authnCreds']['user_id']
    resource_id = presentation['authnCreds']['resource_id']
    resource_type = presentation['authnCreds']['resource_type']

    if !user_id || !resource_id || !resource_type
      render status: 400, json: { errors: 'Invalid authnCreds' }
    end

    user = User.find_by(id: user_id)

    if !user
      render status: 400, json: { errors: 'Unknown user' }
    end

    if resource_type == 'group'
      resource = Group.find_by(id: resource_id)
    end

    if !resource
      render status: 400, json: { errors: 'Unknown resource' }
    end

    verifier = VerifiableCredentials::Verifier.new(
      user: user,
      resource: resource,
      type: SiteSetting.verifiable_credentials_provider.to_sym
    )

    result = verifier.perform(@jwt)

    if result.success?

      if resource_type == 'group'
        resource.add(user)
      end

      redirect_url = resource.custom_fields['verifiable_credentials_redirect']
      redirect_url = resource.url if !redirect_url && resource.respond_to(:url)

      MessageBus.publish("/vc/verified", redirect_url, user_ids: [user.id])
    end
  end
end