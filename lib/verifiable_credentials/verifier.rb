class ::VerifiableCredentials::Verifier
  attr_accessor :user,
                :type
  
  def initialize(user: nil, type: nil)
    @user = user
    @type = type
  end
  
  def perform(presentation, resource: 'group', resource_id: nil)
    verifier = nil
    
    if @type == :vc_ltd
      verifier = VerifiableCredentials::VCLtd.new 
    end
    
    verified = verifier.verify(presentation)
    
    if !verified
      raise Discourse::InvalidAccess.new('No valid credentials') 
    end
    
    result = ::VerifiableCredentials::VerifierResult.new
    
    if resource == 'group' && group = Group.find_by_id(resource_id)
      result.success = group.add(@user)
    end
    
    result
  end
  
  def verify(presentation)
    ## Implementated by verifier classes
  end   
end