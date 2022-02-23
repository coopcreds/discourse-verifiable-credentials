# frozen_string_literal: true

module ::VerifiableCredentials
  NAMESPACE ||= "verifiable_credentials"

  class Engine < ::Rails::Engine
    engine_name NAMESPACE
    isolate_namespace VerifiableCredentials
  end

  def self.base_url
    Rails.env.development? ? "https://d10f-217-8-142-78.ngrok.io" : Discourse.base_url
  end
end
