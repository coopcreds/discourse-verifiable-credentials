# frozen_string_literal: true

class ::VerifiableCredentials::Verifier
  attr_reader :handler,
              :domain,
              :requires_key

  attr_accessor :api_key

  def initialize(handler, require_key: false)
    @handler = handler
    @domain = SiteSetting.verifiable_credentials_verifier_domain
    @requires_key = require_key
  end

  def ready?
    return false unless @domain.present?

    if requires_key
      @api_key = get_api_key unless @api_key.present?
      !!@api_key
    else
      true
    end
  end

  def get_api_key
    ## Implementated by verifier classes
  end

  def create_presentation_request
    ## Implementated by verifier classes
  end

  def presentation_request_uri
    ## Implementated by verifier classes
  end

  def verify(data, opts = {})
    ## Implementated by verifier classes
  end

  def request(type, path, body: {}, url_encoded: false)
    headers = {
      "Accept" => "*/*"
    }
    args = {
      method: type
    }

    if @api_key.present?
      headers["Authorization"] = "Bearer #{@api_key}"
    end

    uri = URI("https://#{@domain}/#{path}")

    if body.present?
      if url_encoded
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        args[:body] = URI.encode_www_form(body)
      else
        headers["Content-Type"] = "application/json"
        args[:body] = body.to_json
      end
    end

    connection = Excon.new(uri.to_s, headers: headers)
    response = connection.request(args)

    return false unless [201, 200].include?(response.status)
    return true unless response.body.present?

    begin
      JSON.parse(response.body)
    rescue => error
      false
    end
  end
end
