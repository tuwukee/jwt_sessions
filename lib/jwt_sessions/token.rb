# frozen_string_literal: true
require 'jwt'

module JWTSessions
  class Token
    def self.encode(payload)
      exp_payload = meta.merge(payload)
      JWT.encode(exp_payload, JWTSessions.encryption_key, JWTSessions.algorithm)
    end

    def self.decode(token)
      JWT.decode(token, JWTSessions.encryption_key, true, { algorithm: JWTSessions.algorithm })
    end

    def self.valid_payload(payload)
      !expired(payload)
    end

    def self.meta
      { exp: Time.now.to_i + JWTSessions.expiration_time.to_i }
    end

    def self.expired(payload)
      Time.at(payload['exp']) < Time.now
    end
  end
end
