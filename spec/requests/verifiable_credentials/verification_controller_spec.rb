# frozen_string_literal: true
require_relative '../../plugin_helper'

describe VerifiableCredentials::VerificationController do
  fab!(:user) { Fabricate(:user) }
  fab!(:group) { Fabricate(:group) }
  fab!(:badge) { Fabricate(:badge) }

  let(:token_json) { get_fixture("token") }
  let(:verifier_json) { get_fixture("verifier") }
  let(:id_token) {
    {
      "sub": verifier_json['verifierDid'],
      "name": "Angus McLeod",
      "iat": 1516239022,
      "group_member": true,
      "badge_holder": true
    }
  }
  let(:provider) { "mattr" }
  let(:verifier_id) { "41458e5a-9092-40b7-9a26-d4eb43c5792f" }
  let(:client_id) { "9092-40b7-9a26-d4eb43c5792f" }
  let(:client_secret) { "12345" }
  let(:verifier_domain) { "pavilion.vii.mattr.global" }
  let(:token_url) { "https://#{verifier_domain}/ext/oidc/v1/verifiers/#{verifier_id}/token" }
  let(:verifier_url) { "https://#{verifier_domain}/ext/oidc/v1/verifiers/#{verifier_id}" }
  let(:token_body) {
    {
      "client_id": client_id,
      "client_secret": client_secret,
      "code": code,
      "grant_type": "authorization_code",
      "redirect_uri": "#{VerifiableCredentials.base_url}/vc/verify/mattr/oidc"
    }
  }
  let(:code) { "oGRCuRMt44-ty8cw" }
  let(:state) { "#{user.id}~~group:#{group.id}|badge:#{badge.id}" }

  def stub_token_request(code)
    token_json['id_token'] = JWT.encode id_token, nil, 'none'
    stub_request(:post, token_url).with(
      body: token_body,
      headers: {
        'Accept': '*/*',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Host': verifier_domain
      }
    ).to_return(status: code, body: token_json.to_json, headers: {})
  end

  def stub_verifier_request(code)
    stub_request(:get, verifier_url).with(
      headers: {
        'Accept': '*/*',
        'Authorization': "Bearer #{token_json['access_token']}",
        'Host': verifier_domain
      }
    ).to_return(status: code, body: verifier_json.to_json, headers: {})
  end

  before do
    SiteSetting.verifiable_credentials_mattr_verifier_id = verifier_id
    SiteSetting.verifiable_credentials_mattr_client_id = client_id
    SiteSetting.verifiable_credentials_mattr_client_secret = client_secret
    SiteSetting.verifiable_credentials_verifier_domain = verifier_domain
  end

  it "grants access to resources when claims are verified" do
    SiteSetting.verifiable_credentials_header_badges = "#{badge.id}~~badge_holder:true"
    group.custom_fields[:verifiable_credentials_credential_claims] = "group_member:true"
    group.save_custom_fields(true)

    stub_token_request(200)
    stub_verifier_request(200)
    get "/vc/verify/#{provider}/oidc?code=#{code}&state=#{URI.encode_www_form_component(state)}"

    expect(response.status).to eq(302)
    expect(group.users.include?(user)).to eq(true)
    expect(UserBadge.where(badge_id: badge.id, user_id: user.id).exists?).to eq(true)
    expect(user.verifiable_credentials.first.did).to eq(verifier_json['verifierDid'])
    expect(user.verifiable_credentials.first.resources.size).to eq(2)
  end
end
