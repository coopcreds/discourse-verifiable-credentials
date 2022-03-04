# frozen_string_literal: true

if ENV['SIMPLECOV']
  require 'simplecov'

  SimpleCov.start do
    root "plugins/discourse-verifiable-credentials"
    track_files "plugins/discourse-verifiable-credentials/**/*.rb"
    add_filter { |src| src.filename =~ /(\/spec\/|\/db\/|plugin\.rb|api|gems)/ }
    SimpleCov.minimum_coverage 80
  end
end

require 'rails_helper'

def get_fixture(path)
  JSON.parse(
    File.open(
      "#{Rails.root}/plugins/discourse-verifiable-credentials/spec/fixtures/#{path}.json"
    ).read
  ).with_indifferent_access
end
