# frozen_string_literal: true

class ::VerifiableCredentials::UserRecordController < ::ApplicationController
  requires_login

  def index
    render_serialized(current_user.verifiable_credentials, VerifiableCredentials::UserRecordSerializer)
  end
end
