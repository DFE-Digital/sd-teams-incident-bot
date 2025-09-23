require "jwt"
require "net/http"
require "json"

class BotAuth
  def self.valid?(authorization:, app_id:)
    scheme, token = (authorization || "").split(" ")
    return false unless scheme&.downcase == "bearer" && token

    conf = fetch_json(ENV.fetch("BOT_OPENID_CONFIG"))
    jwks = fetch_json(conf["jwks_uri"])
    issuer = conf["issuer"]

    JWT.decode(token, nil, true,
      algorithms: ["RS256"],
      jwks: JWT::JWK::Set.new(jwks),
      iss: issuer, verify_iss: true,
      aud: app_id, verify_aud: true
    )
    true
  rescue => _
    false
  end

  def self.fetch_json(url)
    JSON.parse(Net::HTTP.get(URI(url)))
  end
end