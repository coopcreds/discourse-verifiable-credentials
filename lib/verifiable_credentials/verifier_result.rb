class ::VerifiableCredentials::VerifierResult
  attr_accessor :success,
                :resource

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