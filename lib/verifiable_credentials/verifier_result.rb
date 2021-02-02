class ::VerifiableCredentials::VerifierResult
  attr_accessor :success
  
  def initialize
    @success = false
  end
  
  def success?
    @success
  end

  def failed?
    !@success
  end
end