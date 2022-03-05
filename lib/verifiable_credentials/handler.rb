# frozen_string_literal: true

class ::VerifiableCredentials::Handler
  attr_reader :user,
              :provider,
              :resources

  attr_accessor :token,
                :error,
                :oidc,
                :did

  def initialize(user: nil, provider: nil, resources: nil)
    @user = user
    @provider = provider
    @resources = resources
  end

  def perform(data, oidc: false)
    @oidc = oidc
    verifier = verifier_class.new(self)

    @result = ::VerifiableCredentials::Result.new
    return @result unless verifier.ready?

    @result.success = verifier.verify(data, oidc: oidc)

    if @result.success
      process_resources
    end

    if token
      @did = oidc ? token[:id_token][:sub] : token[:claims][:id]
    end

    update_user

    @result
  end

  def create_presentation_request
    verifier = verifier_class.new(self, require_key: true)

    if verifier.ready?
      verifier.create_presentation_request
    else
      false
    end
  end

  def presentation_request_uri
    verifier = verifier_class.new(self)

    if verifier.ready?
      verifier.presentation_request_uri
    else
      false
    end
  end

  def verifier_class
    @verifier_class ||= Module.const_get("VerifiableCredentials::Verifier::#{@provider.to_s.camelize.classify}")
  end

  def credential_identifier
    identifiable_resource = @resources.select { |resource| resource.type === 'group' }

    if identifiable_resource.any?
      identifiable_resource.first.model.custom_fields[:verifiable_credentials_credential_identifier]
    end
  end

  protected

  def process_resources
    return unless @result && @result.success

    resources.each do |resource|
      if match_token_claims(resource.claims)
        resource.verification_success(@user)

        if resource.redirect_on_success.present?
          @result.redirect_url = resource.redirect_on_success
        end
      else
        resource.verification_failure(@user)

        if resource.redirect_on_failure.present?
          @result.redirect_url = resource.redirect_on_failure
        end
      end
    end
  end

  def update_user
    return unless @result

    record = {
      did: @did,
      oidc: oidc,
      provider: provider,
      resources: resources
    }

    if error
      record[:error] = error
    end

    @user.add_verifiable_credentials_record(record)
  end

  def match_token_claims(claims)
    token_claims = @oidc ? token[:id_token] : token[:claims]
    claims.present? && claims.all? { |k, v| token_claims[k].to_s === v.to_s }
  end
end
