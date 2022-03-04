# frozen_string_literal: true

class ::VerifiableCredentials::UserRecordSerializer < ::ApplicationSerializer
  attributes :did,
             :resources,
             :error,
             :created_at

  def resources
    ActiveModel::ArraySerializer.new(
      object.resources,
      each_serializer: VerifiableCredentials::ResourceSerializer
    )
  end

  def include_error?
    object.error.present?
  end
end
