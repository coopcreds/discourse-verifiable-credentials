# frozen_string_literal: true

module ::VerifiableCredentials
  NAMESPACE ||= "verifiable_credentials"

  class Engine < ::Rails::Engine
    engine_name NAMESPACE
    isolate_namespace VerifiableCredentials
  end

  def self.base_url
    Rails.env.development? ? "https://4322-88-93-97-77.ngrok.io" : Discourse.base_url
  end
end
