# frozen_string_literal: true

class ::VerifiableCredentials::Result
  attr_accessor :success,
                :redirect_url

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
