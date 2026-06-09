module Services
  module Identity
  module JwtService
    def self.generate(user_entity, expires_in: 24.hours)
      payload = {
        user_id: user_entity.id,
        tenant_id: user_entity.tenant_id,
        iss: SatuRayaCommons::Config.jwt_issuer,
        exp: expires_in.from_now.to_i,
        iat: Time.current.to_i,
        jti: SecureRandom.uuid
      }
      Domains::ValueObjects::Identity::JwtToken.new(
        value: JWT.encode(payload, Rails.application.secret_key_base, "HS256"),
        expires_at: Time.at(payload[:exp])
      )
    end

    def self.decode(token)
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")[0]
      payload = decoded.symbolize_keys
      Domains::ValueObjects::Identity::JwtToken.new(
        value: token,
        expires_at: Time.at(payload[:exp])
      )
    rescue JWT::DecodeError
      nil
    end
  end
end

end