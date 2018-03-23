# frozen_string_literal: true

module JWTSessions
  class RefreshToken
    attr_reader :expires_at, :uid, :token

    def initialize(uid, expires_at)
      @uid = uid
      @expires_at = expires_at
      @token = Token.encode(uid: uid, exp: expires_at.to_i)
    end

    class << self
      def create(uid, salt, access_token_uid, access_expiration)
        refresh_expiration = Time.now + JWTSessions.refresh_exp_time
        persist_in_store(uid, salt, access_token_uid, access_expiration, refresh_expiration)
        new(uid, refresh_expiration)
      end

      def find(uid)
        token_attrs = TokenStore.get_refresh(uid)
        raise Errors::Unauthorized, 'Refresh token not found' if token_attrs.empty?
        new(uid, token_attrs[:refresh_expires_at])
      end
    end

    def update_salt(new_salt)
      TokenStore.update_refresh_salt(uid, new_salt)
    end

    def destroy
      TokenStore.destroy_refresh(uid)
    end

    private

    def persist_in_store(uid, salt, access_token_uid, access_expiration, refresh_expiration)
      token = {
        access_expires_at: access_expiration,
        refresh_expires_at: refresh_expiration,
        salt: salt,
        access_uid: access_token_uid
      }
      TokenStore.set_refresh(uid, token)
    end
  end
end
