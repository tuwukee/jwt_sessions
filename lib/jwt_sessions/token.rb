# frozen_string_literal: true

require 'jwt'

module JWTSessions
  class Token
    class << self
      def encode(payload)
        exp_payload = meta.merge(payload)
        JWT.encode(exp_payload, JWTSessions.encryption_key, JWTSessions.algorithm)
      end

      def decode(token)
        JWT.decode(token, JWTSessions.encryption_key, true, { algorithm: JWTSessions.algorithm, verify_expiration: false })
      rescue JWT::DecodeError => e
        raise Errors::Unauthorized, e.message
      rescue StandardError
        raise Errors::Unauthorized, 'could not decode a token'
      end

      def valid_payload?(payload)
        !expired?(payload)
      end

      def meta
        { exp: JWTSessions.access_expiration }
      end

      def expired?(payload)
        Time.at(payload['exp']) < Time.now
      rescue StandardError
        raise Errors::Unauthorized, 'invalid payload expiration time'
      end
    end
  end
end
