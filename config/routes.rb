# frozen_string_literal: true
VerifiableCredentials::Engine.routes.draw do
  get "presentation/:provider/initiate" => "presentation#initiate"
  post "presentation/:provider/create" => "presentation#create"
  post "verify/:provider" => "verification#verify"
  get "verify/:provider/oidc" => "verification#verify_oidc"
  get "verification-error" => "verification#verification_error"
  get "user/records" => "user_record#index"
end

Discourse::Application.routes.prepend do
  mount ::VerifiableCredentials::Engine, at: "vc"
  get "/u/:username/credentials" => "users#index"
  get "/u/:username/credentials/records" => "users#index"
end
