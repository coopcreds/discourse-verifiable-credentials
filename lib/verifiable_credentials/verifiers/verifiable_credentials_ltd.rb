class ::VerifiableCredentials::VerifiableCredentialsLtd < ::VerifiableCredentials::Verifier
  attr_accessor :domain

  def initialize(policy)
    @domain = SiteSetting.verifiable_credentials_verifier_domain
    @policy = policy
  end

  def verify(presentation)
    request_access_decision(presentation)
  end

  def request_access_decision(presentation)
    request("POST", "v1/decisionBasicAuthn", 
      atts: false,
      policyMatch: @policy,
      vpjwt: presentation
    )
  end

  def request(type, path, body)
    connection = Excon.new(
      "https://#{@domain}/#{path}",
      :headers => {
        "Accept" => "application/json, */*",
        "Content-Type" => "application/json"
      }
    )

    response = connection.request(
      method: type,
      body: body.to_json
    )

    true #response.body.present? ? JSON.parse(response.body) : nil
  end
end