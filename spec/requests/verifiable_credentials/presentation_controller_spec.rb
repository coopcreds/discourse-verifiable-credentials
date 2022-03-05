# frozen_string_literal: true
require_relative '../../plugin_helper'

describe VerifiableCredentials::PresentationController do
  fab!(:user) { Fabricate(:user) }
  fab!(:group) { Fabricate(:group) }
  fab!(:badge) { Fabricate(:badge) }

  let(:provider) { "mattr" }
  let(:verifier_id) { "41458e5a-9092-40b7-9a26-d4eb43c5792f" }
  let(:client_id) { "9092-40b7-9a26-d4eb43c5792f" }
  let(:verifier_domain) { "pavilion.vii.mattr.global" }
  let(:well_known_url) { "https://#{verifier_domain}/ext/oidc/v1/verifiers/#{verifier_id}/.well-known/openid-configuration" }
  let(:well_known) {
    {
      "authorization_endpoint": "https://#{verifier_domain}/ext/oidc/v1/verifiers/#{verifier_id}/authorize"
    }
  }
  let(:state) { "#{user.id}~~group:#{group.id}|badge:#{badge.id}" }
  let(:resources) { [ { type: 'group', id: group.id }, { type: 'badge', id: badge.id } ] }

  def stub_well_known_request(code)
    stub_request(:get, well_known_url).with(
      headers: {
        'Accept': '*/*',
        'Host': verifier_domain
      }
    ).to_return(status: code, body: well_known.to_json, headers: {})
  end

  before do
    SiteSetting.verifiable_credentials_mattr_verifier_id = verifier_id
    SiteSetting.verifiable_credentials_mattr_client_id = client_id
    SiteSetting.verifiable_credentials_verifier_domain = verifier_domain
  end

  it "initiates an oidc presentation request" do
    SiteSetting.verifiable_credentials_header_badges = "#{badge.id}~~badge_holder~~true"
    group.custom_fields[:verifiable_credentials_credential_claims] = "group_member:true"
    group.save_custom_fields(true)
    sign_in(user)

    stub_well_known_request(200)
    resources_str = resources.map { |r| "#{r[:type]}:#{r[:id]}" }.join('|')
    get "/vc/presentation/#{provider}/initiate?resources=#{URI.encode_www_form_component(resources_str)}"

    expect(response.status).to eq(302)
    expect(response.location).to include("state=#{URI.encode_www_form_component(state)}")
  end
end
