class ::VerifiableCredentials::Verifier
  attr_accessor :user,
                :type,
                :resource

  def initialize(user: nil, type: nil, resource: nil)
    @user = user
    @type = type
    @resource = resource
  end

  def perform(presentation)
    klass = Module.const_get("VerifiableCredentials::#{@type.to_s.camelize.classify}")

    policy = {
      type: @resource.custom_fields[:verifiable_credentials_credential]
    }

    verifier = klass.new(policy)    
    result = ::VerifiableCredentials::VerifierResult.new
    result.success = verifier.verify(presentation)

    result
  end
  
  def verify(presentation)
    ## Implementated by verifier classes
  end   
end