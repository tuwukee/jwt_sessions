# frozen_string_literal: true

require "jwt"

module JWTSessions
  class Token
    DECODE_ERROR = "cannot decode the token"

    class << self
      def encode(payload)
        exp_payload = meta.merge(payload)
        JWT.encode(exp_payload, JWTSessions.private_key, JWTSessions.algorithm)
      end

      def decode(token, claims = {})
        decode_options = { algorithm: JWTSessions.algorithm }.merge(JWTSessions.jwt_options).merge(claims)
        JWT.decode(token, JWTSessions.public_key, JWTSessions.validate?, decode_options)
      rescue JWT::ExpiredSignature => e
        raise Errors::Expired, e.message
      rescue JWT::InvalidIssuerError, JWT::InvalidIatError, JWT::InvalidAudError, JWT::InvalidSubError, JWT::InvalidJtiError => e
        raise Errors::ClaimsVerification, e.message
      rescue JWT::DecodeError => e
        raise Errors::Unauthorized, e.message
      rescue StandardError
        raise Errors::Unauthorized, DECODE_ERROR
      end

      def decode!(token)
        decode_options = { algorithm: JWTSessions.algorithm }
        JWT.decode(token, JWTSessions.public_key, false, decode_options)
      rescue StandardError
        raise Errors::Unauthorized, DECODE_ERROR
      end

      def meta
        { "exp" => JWTSessions.access_expiration }
      end
    end
  end
end
