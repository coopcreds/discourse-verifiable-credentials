# frozen_string_literal: true

class ::VerifiableCredentials::Resource
  include ActiveModel::Serialization

  attr_reader :type,
              :id

  attr_accessor :verified

  CLAIM_DELIMITER = ':'
  LIST_DELIMITER = '|'
  ID_DELIMITER = '~~'

  attr_accessor :model

  def initialize(type, id)
    @type = type
    @id = id
  end

  def find
    if type === 'group'
      @model = Group.find_by(id: id)
    end
    if type === 'badge'
      @model = Badge.find_by(id: id)
    end
  end

  def found?
    !!model
  end

  def claims
    @claims ||= begin
      if type === 'group'
        self.class.split_group_claims(
          model.custom_fields[:verifiable_credentials_credential_claims]
        )
      elsif type === 'badge'
        self.class.split_badge_claims(
          SiteSetting.verifiable_credentials_badge_claims
        )[id]
      end
    end
  end

  def verification_success(user)
    if type === 'group'
      model.add(user, notify: true)
    end
    if type === 'badge'
      BadgeGranter.grant(model, user) if user
    end

    @verified = true
  end

  def verification_failure(user)
    @verified = false
  end

  def redirect_on_success
    if type === 'group'
      model.custom_fields[:verifiable_credentials_redirect]
    end
  end

  def redirect_on_failure
    if type === 'group'
      "/g/#{@model.name}?failed_to_verify=true"
    end
  end

  def self.join(resources = [])
    string = +""

    resources.each_with_index do |resource, index|
      string << LIST_DELIMITER if index > 0
      string << "#{resource.type}#{CLAIM_DELIMITER}#{resource.id}"
      string << "#{CLAIM_DELIMITER}#{resource.verified}" if !resource.verified.nil?
    end

    string
  end

  def self.split(string = "")
    string.split(LIST_DELIMITER).reduce([]) do |result, resource|
      parts = resource.split(CLAIM_DELIMITER)

      if parts.length > 1
        resource = new(parts.first, parts.second.to_i)

        if parts.length === 3
          resource.verified = ActiveRecord::Type::Boolean.new.cast(parts.last)
        end

        result << resource
      end

      result
    end
  end

  def self.split_group_claims(string = "")
    string.split(LIST_DELIMITER).reduce({}) do |result, claim_str|
      parts = claim_str.rpartition(CLAIM_DELIMITER)

      if parts.length > 1
        claim = parts.first
        value = parts.last

        result[claim] = value
      end

      result
    end
  end

  def self.split_badge_claims(string = "")
    string.split(LIST_DELIMITER).reduce({}) do |result, claim_str|
      parts = claim_str.split(ID_DELIMITER)

      if parts.length > 1
        badge_id = parts.first.to_i
        claims_parts = parts.second.rpartition(CLAIM_DELIMITER)

        if claims_parts.length > 1
          claim = claims_parts.first
          value = claims_parts.last

          result[badge_id] ||= {}
          result[badge_id][claim] = value
        end
      end

      result
    end
  end

  def self.find_all(resources)
    resources.reduce([]) do |result, resource|
      resource.find

      if resource.found?
        result << resource
      end

      result
    end
  end
end
