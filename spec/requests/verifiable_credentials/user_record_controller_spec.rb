# frozen_string_literal: true
require_relative '../../plugin_helper'

describe VerifiableCredentials::UserRecordController do
  fab!(:user) { Fabricate(:user) }
  fab!(:group) { Fabricate(:group) }
  fab!(:badge) { Fabricate(:badge) }

  let(:provider) { 'mattr' }
  let(:did) { "did:key:z6Mkv7Lv5vJqfRs3fxVeJu1y8xDKXFnDZ8WcudMwZSpQhGKJ" }
  let(:resources) { [ { type: 'group', id: group.id }, { type: 'badge', id: badge.id } ] }

  it "returns user records" do
    record = {
      did: did,
      provider: provider,
      resources: VerifiableCredentials::Resource.find_all(
        resources.map do |resource|
          resource = VerifiableCredentials::Resource.new(resource[:type], resource[:id])
          resource.verified = resource.type === 'group'
          resource
        end
      )
    }
    user.add_verifiable_credentials_record(record)
    sign_in(user)

    get "/vc/user/records.json"

    expect(response.status).to eq(200)
    response_record = response.parsed_body.first
    expect(response_record['did']).to eq(did)
    expect(response_record['resources'].size).to eq(2)
    expect(response_record['resources'].select { |r| r['type'] === "group" }.first['verified']).to eq(true)
  end
end
