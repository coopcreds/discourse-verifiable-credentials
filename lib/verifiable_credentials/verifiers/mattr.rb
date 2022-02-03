# frozen_string_literal: true

class ::VerifiableCredentials::Verifier::Mattr < ::VerifiableCredentials::Verifier
  def create_presentation_request
    verifier_did = SiteSetting.verifiable_credentials_verifier_did
    verifier_document = request('GET', "core/v1/dids/#{verifier_did}")
    return false if !verifier_document

    body = {
      "challenge": "#{@handler.resource_type}:#{@handler.resource.id}:#{@handler.user.id}",
      "did": verifier_did,
      "templateId": @handler.resource.custom_fields[:verifiable_credentials_credential],
      "callbackUrl": "#{VerifiableCredentials.base_url}/vc/verify-mattr"
    }
    result = request('POST', 'core/v1/presentations/requests', body)
    return false if !result

    jws = request('POST', 'core/v1/messaging/sign',
      didUrl: verifier_document['didDocument']['authentication'][0],
      payload: result['request']
    )

    jws
  end

  def verify(data)
    data['verified']
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

  def requires_key
    true
  end
end
