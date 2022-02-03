VerifiableCredentials::Engine.routes.draw do
  post "create-presentation-request" => "presentation#create_request"
  post "verify-vcltd" => "verify#verify"
  post "verify-mattr" => "verify#verify"
end

Discourse::Application.routes.prepend do
  mount ::VerifiableCredentials::Engine, at: "vc"
end
