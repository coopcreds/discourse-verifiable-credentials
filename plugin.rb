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
    ../lib/verifiable_credentials/resource.rb
    ../lib/verifiable_credentials/handler.rb
    ../lib/verifiable_credentials/result.rb
    ../lib/verifiable_credentials/user_record.rb
    ../lib/verifiable_credentials/verifier.rb
    ../lib/verifiable_credentials/verifiers/mattr.rb
    ../lib/verifiable_credentials/verifiers/verifiable_credentials_ltd.rb
    ../app/serializers/verifiable_credentials/badge_serializer.rb
    ../app/serializers/verifiable_credentials/group_serializer.rb
    ../app/serializers/verifiable_credentials/resource_serializer.rb
    ../app/serializers/verifiable_credentials/user_record_serializer.rb
    ../app/controllers/verifiable_credentials/verification_controller.rb
    ../app/controllers/verifiable_credentials/user_record_controller.rb
    ../app/controllers/verifiable_credentials/presentation_controller.rb
    ../config/routes.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  {
    verifiable_credentials_redirect: :string,
    verifiable_credentials_credential_identifier: :string,
    verifiable_credentials_credential_claims: :string,
    verifiable_credentials_allow_membership: :boolean,
    verifiable_credentials_show_button: :boolean
  }.each do |key, type|
    register_editable_group_custom_field(key)
    register_group_custom_field_type(key.to_s, type)
  end

  add_to_serializer(:basic_group, :custom_fields) { object.custom_fields }
  add_to_serializer(:site, :credential_badges) do
    badge_ids = VerifiableCredentials::Resource.split_badge_claims(
      SiteSetting.verifiable_credentials_header_badges
    ).keys

    if badge_ids.any?
      ActiveModel::ArraySerializer.new(
        Badge.where(id: badge_ids),
        each_serializer: VerifiableCredentials::BadgeSerializer,
        root: false
      )
    end
  end

  add_to_serializer(:site, :credential_groups) do
    groups_names = SiteSetting.verifiable_credentials_header_groups.split('|')

    if groups_names.any?
      ActiveModel::ArraySerializer.new(
        Group.where(name: groups_names),
        each_serializer: VerifiableCredentials::GroupSerializer,
        root: false
      )
    end
  end

  register_user_custom_field_type(:verifiable_credentials_record, :json)

  add_to_class(:user, :verifiable_credentials_records) do
    if !custom_fields[:verifiable_credentials_record].nil?
      [*custom_fields[:verifiable_credentials_record]].map do |credential|
        JSON.parse(credential).with_indifferent_access
      end
    else
      []
    end
  end

  add_to_class(:user, :verifiable_credentials) do
    if verifiable_credentials_records.length
      verifiable_credentials_records.map do |record|
        VerifiableCredentials::UserRecord.new(record)
      end
    else
      []
    end
  end

  add_to_class(:user, :add_verifiable_credentials_record) do |did: nil, provider: nil, oidc: nil, resources: [], error: nil|
    records = verifiable_credentials_records
    record = {
      did: did,
      oidc: oidc,
      provider: provider,
      resources: VerifiableCredentials::Resource.join(resources),
      created_at: Time.now.iso8601
    }

    if error
      record[:error] = error
    end

    records << record
    custom_fields[:verifiable_credentials_record] = records.map(&:to_json)

    save_custom_fields(true)
  end

  add_to_serializer(:current_user, :verifiable_credential_badges) do
    badge_ids = VerifiableCredentials::Resource.split_badge_claims(
      SiteSetting.verifiable_credentials_header_badges
    ).keys

    if badge_ids.any?
      ActiveModel::ArraySerializer.new(
        object.badges.where(id: badge_ids),
        each_serializer: VerifiableCredentials::BadgeSerializer,
        root: false
      )
    else
      []
    end
  end
end
