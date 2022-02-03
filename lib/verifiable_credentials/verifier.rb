# frozen_string_literal: true

class ::VerifiableCredentials::Verifier
  attr_reader :handler,
              :domain

  def initialize(handler)
    @handler = handler
    @domain = SiteSetting.verifiable_credentials_verifier_domain
  end

  def create_presentation_request
    ## Implementated by verifier classes
  end 

  def verify(data)
    ## Implementated by verifier classes
  end

  def request(type, path, body = {})
    if requires_key
      api_key = get_api_key
    end

    headers = {
      "Accept" => "*/*"
    }
    args = {
      method: type
    }

    if requires_key && api_key
      headers["Authorization"] = "Bearer #{api_key}"
    end

    if body.present?
      headers["Content-Type"] = "application/json"
      args[:body] = body.to_json
    end

    url = "https://#{@domain}/#{path}"
    connection = Excon.new(url, :headers => headers)
    response = connection.request(args)

    return false unless [201, 200].include?(response.status)
    return true unless response.body.present?

    begin
      JSON.parse(response.body)
    rescue => error
      false
    end
  end

  def get_api_key
    ## Implementated by verifier classes
  end
end