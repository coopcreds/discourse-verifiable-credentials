VerifiableCredentials::Engine.routes.draw do
  post "verify" => "verify#perform"
end

Discourse::Application.routes.append do
  mount ::VerifiableCredentials::Engine, at: "vc"
end