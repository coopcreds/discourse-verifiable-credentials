# frozen_string_literal: true

class ::VerifiableCredentials::Verify
  attr_reader :user,
              :provider,
              :resource,
              :resource_type

  def initialize(user: nil, provider: nil, resource: nil, resource_type: nil)
    @user = user
    @provider = provider
    @resource = resource
    @resource_type = resource_type
  end

  def perform(data, oidc: false)
    verifier = verifier_class.new(self)

    result = ::VerifiableCredentials::VerifyResult.new
    result.success = verifier.verify(data, oidc: oidc)
    result
  end

  def create_presentation_request
    verifier = verifier_class.new(self, require_key: true)

    if verifier.ready?
      verifier.create_presentation_request
    else
      false
    end
  end

  def presentation_request_uri
    verifier = verifier_class.new(self)

    if verifier.ready?
      verifier.presentation_request_uri
    else
      false
    end
  end

  def verifier_class
    @verifier_class ||= Module.const_get("VerifiableCredentials::Verifier::#{@provider.to_s.camelize.classify}")
  end
end
