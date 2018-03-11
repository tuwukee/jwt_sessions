# frozen_string_literal: true

require 'securerandom'

module JWTSessions
  class RefreshToken
    CSRF_LENGTH = 32
    attr_reader :expires_at, :uid
    attr_accessor :salt

    class << self
      def create(uid)
        token = {
          expires_at: Time.now + JWTSessions.refresh_exp_time,
          salt: SecureRandom.base64(CSRF_LENGTH),
          uid: uid
        }
        TokenStore.set_refresh(token)
        new(token.values)
      end

      def find(uid)
        token_attrs = TokenStore.get_refresh(uid)
        raise Errors::Unauthorized, 'Refresh token not found' if token_attrs.empty?
        new(token_attrs)
      end

      def destroy(uid)
        TokenStore.destroy_refresh(uid)
      end
    end

    def initialize(attrs)
      @expires_at, @salt, @uid = attrs
    end

    def update_salt
      token = {
        expires_at: expires_at,
        salt: SecureRandom.base64(CSRF_LENGTH),
        uid: uid
      }
      TokenStore.set_refresh(token)
      self.salt = token[:salt]
    end
  end
end
