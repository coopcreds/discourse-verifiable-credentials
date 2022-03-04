# frozen_string_literal: true

class ::VerifiableCredentials::ResourceSerializer < ::ApplicationSerializer
  attributes :id,
             :type,
             :verified
end
