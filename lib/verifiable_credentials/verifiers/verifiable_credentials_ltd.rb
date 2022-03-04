# frozen_string_literal: true

class ::VerifiableCredentials::Verifier::VerifiableCredentialsLtd < VerifiableCredentials::Verifier
  def verify(data, opts = {})
    request("POST", "v1/decisionBasicAuthn",
      atts: false,
      policyMatch: {
        type: @handler.credential_identifier
      },
      vpjwt: data
    )
  end
end
