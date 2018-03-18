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
        JWT.decode(token, JWTSessions.encryption_key, true, { algorithm: JWTSessions.algorithm })
      rescue StandardError
        raise Errors::Unauthorized, 'cannot decode the token'
      end

      def valid_payload?(payload)
        !expired?(payload)
      end

      def meta
        { exp: Time.now.to_i + JWTSessions.exp_time.to_i }
      end

      def expired?(payload)
        Time.at(payload['exp']) < Time.now
      rescue StandardError
        raise Errors::Unauthorized, 'invalid payload expiration time'
      end
    end
  end
end
