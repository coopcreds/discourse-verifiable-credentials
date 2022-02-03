# frozen_string_literal: true

class ::VerifiableCredentials::Verifier::VerifiableCredentialsLtd < VerifiableCredentials::Verifier
  def verify(data)
    request("POST", "v1/decisionBasicAuthn", 
      atts: false,
      policyMatch: {
        type: @resource.custom_fields[:verifiable_credentials_credential]
      },
      vpjwt: data
    )
  end
end
