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
    ../lib/verifiable_credentials/verifier.rb
    ../lib/verifiable_credentials/verifier_result.rb
    ../lib/verifiable_credentials/verifiers/vc_ltd.rb
    ../app/controllers/verifiable_credentials/verify.rb
    ../config/routes.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  register_editable_group_custom_field(:allow_membership_by_verifiable_credentials)
  register_group_custom_field_type('allow_membership_by_verifiable_credentials', :boolean)
  register_editable_group_custom_field(:verifiable_credentials_redirect)
  register_group_custom_field_type('verifiable_credentials_redirect', :string)
  add_to_serializer(:basic_group, :custom_fields) { object.custom_fields }
end