# frozen_string_literal: true

class ::VerifiableCredentials::Verifier::Mattr < ::VerifiableCredentials::Verifier
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
      state: "#{@handler.resource_type}:#{@handler.resource.id}:#{@handler.user.id}",
      nonce: SecureRandom.hex(10)
    )
    uri.to_s
  end

  def create_presentation_request
    verifier_did = SiteSetting.verifiable_credentials_mattr_verifier_did
    verifier_document = request('GET', "core/v1/dids/#{verifier_did}")
    return false if !verifier_document

    body = {
      "challenge": "#{@handler.resource_type}:#{@handler.resource.id}:#{@handler.user.id}",
      "did": verifier_did,
      "templateId": @handler.resource.custom_fields[:verifiable_credentials_credential_identifier],
      "callbackUrl": "#{VerifiableCredentials.base_url}/vc/verify/mattr"
    }
    result = request('POST', 'core/v1/presentations/requests', body)
    return false if !result

    jws = request('POST', 'core/v1/messaging/sign',
      didUrl: verifier_document['didDocument']['authentication'][0],
      payload: result['request']
    )

    jws
  end

  def verify(data, opts = {})
    if opts[:oidc]
      verifier_id = SiteSetting.verifiable_credentials_mattr_verifier_id
      client_id = SiteSetting.verifiable_credentials_mattr_client_id
      client_secret = SiteSetting.verifiable_credentials_mattr_client_secret
      code = data[:code]

      return false unless verifier_id.present? &&
        client_id.present? &&
        client_secret.present? &&
        code.present?

      body = {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: "#{VerifiableCredentials.base_url}/vc/verify/mattr/oidc"
      }

      token_result = request('POST', "ext/oidc/v1/verifiers/#{verifier_id}/token", body, url_encoded: true)
      return false unless token_result

      token = JWT.decode token_result['id_token'], nil, false
      return false unless token.present?

      token = token.first
      claims = @handler.resource.custom_fields[:verifiable_credentials_credential_claims]

      if claims.present?
        claims = claims.split(',').reduce({}) do |result, c|
          parts = c.rpartition(':')
          result[parts.first] = parts.last
          result
        end
        claims_in_token = token.slice(*claims.keys)

        return false unless claims_in_token.present?
        return false unless claims_in_token.all? do |k, v|
          claims_in_token[k] === claims[k]
        end
      end

      true
    else
      data['verified']
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
