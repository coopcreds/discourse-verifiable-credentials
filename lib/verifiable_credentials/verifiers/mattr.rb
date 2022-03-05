# frozen_string_literal: true

class ::VerifiableCredentials::Verifier::Mattr < ::VerifiableCredentials::Verifier
  def build_state
    "#{@handler.user.id}~~#{VerifiableCredentials::Resource.join(@handler.resources)}"
  end

  def presentation_request_uri
    verifier_id = SiteSetting.verifiable_credentials_mattr_verifier_id
    client_id = SiteSetting.verifiable_credentials_mattr_client_id
    return false unless verifier_id && client_id

    openid_config = request('GET', "ext/oidc/v1/verifiers/#{verifier_id}/.well-known/openid-configuration")
    return false if !openid_config || !openid_config['authorization_endpoint']

    uri = URI(openid_config['authorization_endpoint'])
    uri.query = URI.encode_www_form(
      response_type: 'code',
      client_id: client_id,
      redirect_uri: "#{VerifiableCredentials.base_url}/vc/verify/mattr/oidc",
      scope: "openid openid_credential_presentation",
      state: build_state,
      nonce: ""
    )
    uri.to_s
  end

  def create_presentation_request
    messaging_did = SiteSetting.verifiable_credentials_mattr_messaging_did
    messaging_document = request('GET', "core/v1/dids/#{messaging_did}")
    return false if !messaging_document

    presentation_template_id = @handler.credential_identifier
    return false if !presentation_template_id

    presentation_body = {
      challenge: build_state,
      did: messaging_did,
      templateId: presentation_template_id,
      callbackUrl: "#{VerifiableCredentials.base_url}/vc/verify/mattr"
    }
    result = request('POST', 'core/v1/presentations/requests', body: presentation_body)
    return false if !result

    signing_body = {
      didUrl: messaging_document['didDocument']['authentication'][0],
      payload: result['request']
    }
    jws = request('POST', 'core/v1/messaging/sign', body: signing_body)
    jws
  end

  def verify(data, opts = {})
    if opts[:oidc]
      verifier_id = SiteSetting.verifiable_credentials_mattr_verifier_id
      client_id = SiteSetting.verifiable_credentials_mattr_client_id
      client_secret = SiteSetting.verifiable_credentials_mattr_client_secret
      code = data[:code]

      unless verifier_id.present? && client_id.present? && client_secret.present? && code.present?
        @handler.error = "Incorrect site configuration"
        return false
      end

      body = {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: "#{VerifiableCredentials.base_url}/vc/verify/mattr/oidc"
      }

      token = request('POST', "ext/oidc/v1/verifiers/#{verifier_id}/token", body: body, url_encoded: true)
      unless token.present?
        @handler.error = "Unable to retrieve token from verifier"
        return false
      end

      token['id_token'] = JWT.decode token['id_token'], nil, false
      unless token['id_token'].present? && token['id_token'].first.is_a?(Hash)
        @handler.error = "Invalid token returned from verifier"
        return false
      end

      token['id_token'] = token['id_token'].first
      @handler.token = token.with_indifferent_access

      true
    else
      return false unless data.present? && data.is_a?(Hash)
      @handler.token = data.with_indifferent_access
      @handler.token[:verified]
    end
  end

  def get_api_key
    stored = PluginStore.get(VerifiableCredentials::NAMESPACE, 'mattr_token')

    if stored && stored['expires_at'] && stored['expires_at'] > Time.now.iso8601
      return stored['token']
    end

    headers = {
      "Content-Type" => "application/json"
    }
    body = {
      client_id: SiteSetting.verifiable_credentials_mattr_client_id,
      client_secret: SiteSetting.verifiable_credentials_mattr_client_secret,
      audience: "https://vii.mattr.global",
      grant_type: "client_credentials"
    }.to_json

    response = Excon.post("https://auth.mattr.global/oauth/token",
      body: body,
      headers: headers
    )

    unless response.status == 200 && response.body.present?
      return nil
    end

    begin
      body = JSON.parse(response.body)
    rescue => error
      return false
    end

    PluginStore.set(VerifiableCredentials::NAMESPACE, 'mattr_token',
      token: body["access_token"],
      expires_at: (Time.now + body["expires_in"].seconds).iso8601
    )

    body["access_token"]
  end
end
