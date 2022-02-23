# frozen_string_literal: true

# name: discourse-verifiable-credentials
# about: Implements verifiable credentials in Discourse
# version: 1.0
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-verifiable-credentials

register_asset "stylesheets/verifiable-credentials.scss"

if respond_to?(:register_svg_icon)
  register_svg_icon "passport"
end

after_initialize do
  %w[
    ../lib/verifiable_credentials/engine.rb
    ../lib/verifiable_credentials/verify.rb
    ../lib/verifiable_credentials/verify_result.rb
    ../lib/verifiable_credentials/verifier.rb
    ../lib/verifiable_credentials/verifiers/mattr.rb
    ../lib/verifiable_credentials/verifiers/verifiable_credentials_ltd.rb
    ../app/controllers/verifiable_credentials/verify_controller.rb
    ../app/controllers/verifiable_credentials/presentation_controller.rb
    ../config/routes.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  register_editable_group_custom_field(:allow_membership_by_verifiable_credentials)
  register_group_custom_field_type('allow_membership_by_verifiable_credentials', :boolean)

  [
    :verifiable_credentials_redirect,
    :verifiable_credentials_credential_identifier,
    :verifiable_credentials_credential_claims,
    :verifiable_credentials_message
  ].each do |key|
    register_editable_group_custom_field(key)
    register_group_custom_field_type(key.to_s, :string)
  end

  add_to_serializer(:basic_group, :custom_fields) { object.custom_fields }
end
