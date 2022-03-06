# frozen_string_literal: true

class VerifiableCredentials::GroupSerializer < ApplicationSerializer
  attributes :id,
             :name,
             :full_name
end
