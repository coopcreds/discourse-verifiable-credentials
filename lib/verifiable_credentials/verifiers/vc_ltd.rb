class ::VerifiableCredentials::VCLtd < ::VerifiableCredentials::Verifier
  attr_accessor :domain
  
  def initialize
    @domain = "http://127.0.0.1:1880"
  end
  
  def verify(presentation)
    request_access_decision(presentation)
  end
  
  def request_access_decision(presentation)
    request("POST", "v1/RequestAccessDecision", 
      atts: false,
      policyMatch: {},
      vpjwt: presentation
    )
  end
  
  def request(type, path, body)
    connection = Excon.new(
      "#{@domain}/#{path}",
      :headers => {
        "Accept" => "application/json, */*",
        "Content-Type" => "application/json"
      }
    )
        
    response = connection.request(
      method: type,
      body: body.to_json
    )
    
    response.body.present? ? JSON.parse(response.body) : nil
  end
end