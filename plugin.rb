# frozen_string_literal: true

# name: discourse-verifiable-credentials
# about: Implements verifiable credentials in Discourse
# version: 1.0
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-verifiable-credentials

if respond_to?(:register_svg_icon)
  register_svg_icon "passport"
end

after_initialize do
  %w[
    ../lib/verifiable_credentials/engine.rb
    ../lib/verifiable_credentials/verifier.rb
    ../lib/verifiable_credentials/verifier_result.rb
    ../lib/verifiable_credentials/verifiers/vc_ltd.rb
    ../app/controllers/verifiable_credentials/verify.rb
    ../config/routes.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
end