# frozen_string_literal: true

class ::VerifiableCredentials::UserRecord
  include ActiveModel::Serialization

  attr_reader :did,
              :provider,
              :resources,
              :error,
              :access_token,
              :created_at

  def initialize(attrs)
    @did = attrs[:did]
    @provider = attrs[:provider]
    @resources = VerifiableCredentials::Resource.split(attrs[:resources])
    @error = attrs[:error]
    @access_token = attrs[:access_token]
    @created_at = attrs[:created_at]
  end
end
