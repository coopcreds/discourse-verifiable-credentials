VerifiableCredentials::Engine.routes.draw do
  get "presentation/:provider/initiate" => "presentation#initiate"
  post "presentation/:provider/create" => "presentation#create"
  post "verify/:provider" => "verify#verify"
  get "verify/:provider/oidc" => "verify#verify_oidc"
end

Discourse::Application.routes.prepend do
  mount ::VerifiableCredentials::Engine, at: "vc"
end
