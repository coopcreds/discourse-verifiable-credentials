# frozen_string_literal: true

class ::VerifiableCredentials::Verify
  attr_reader :user,
              :type,
              :resource,
              :resource_type

  def initialize(user: nil, type: nil, resource: nil, resource_type: nil)
    @user = user
    @type = type
    @resource = resource
    @resource_type = resource_type
  end

  def perform(data)
    verifier = verifier_class.new(self)

    result = ::VerifiableCredentials::VerifyResult.new
    result.success = verifier.verify(data)
    result
  end

  def create_presentation_request
    verifier = verifier_class.new(self)
    verifier.create_presentation_request
  end

  def verifier_class
    @verifier_class ||= Module.const_get("VerifiableCredentials::Verifier::#{@type.to_s.camelize.classify}")
  end
end
