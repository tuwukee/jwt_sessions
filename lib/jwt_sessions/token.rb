# frozen_string_literal: true

require 'jwt'

module JWTSessions
  class Token
    class << self
      def encode(payload)
        exp_payload = meta.merge(payload)
        JWT.encode(exp_payload, JWTSessions.private_key, JWTSessions.algorithm)
      end

      def decode(token, claims = {})
        decode_options = { algorithm: JWTSessions.algorithm }.merge(JWTSessions.jwt_options.to_h).merge(claims)
        JWT.decode(token, JWTSessions.public_key, JWTSessions.validate?, decode_options)
      rescue JWT::DecodeError => e
        raise Errors::Unauthorized, e.message
      rescue StandardError
        raise Errors::Unauthorized, 'could not decode a token'
      end

      def meta
        { exp: JWTSessions.access_expiration }
      end
    end
  end
end
