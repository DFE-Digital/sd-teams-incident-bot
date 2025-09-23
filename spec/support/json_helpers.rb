# frozen_string_literal: true
module JsonHelpers
  def json_headers
    { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
  end

  def parsed
    JSON.parse(response.body)
  end

  def json_post(path, body, headers: {})
    post path, params: body.to_json, headers: json_headers.merge(headers)
  end
end

RSpec.configure do |config|
  config.include JsonHelpers
end