# frozen_string_literal: true

require 'redis'

module JWTSessions
  class TokenStore
    class << self
      def instance
        @_tokens_store ||= Redis.new(url: "#{JWTSessions.redis_host}/#{JWTSessions.redis_db_name}")
      end

      def get_csrf(uid)
        instance.get("#{JWTSessions.token_prefix}_#{uid}")
      end

      def set_refresh(auth_id, uid, token)
        key = refresh_key(auth_id, uid)
        instance.hmset(key,
                       :access_expires_at, token.fetch(:access_expires_at),
                       :refresh_expires_at, token.fetch(:refresh_expires_at),
                       :salt, token.fetch(:salt),
                       :access_uid, token.fetch(:uid))
        instance.expireat(key, token[:refresh_expires_at].to_i)
      end

      def get_refresh(uid)
        instance.hmget(refresh_key(uid), :access_expires_at, :refresh_expires_at, :salt, :access_uid)
      end

      def update_refresh_salt(uid, new_salt)
        instance.hset(refresh_key(uid), :salt, new_salt)
      end

      def destroy_refresh(uid)
        instance.del(refresh_key(uid))
      end

      def set_access(uid, salt, exp)
        key = access_key(uid)
        instance.set(key, salt)
        instance.expireat(key, exp)
      end

      def get_access(uid)
        instance.get(access_key(uid))
      end

      def destroy_access(uid)
        instance.del(access_key(uid))
      end

      private

      def access_key(uid)
        "#{JWTSessions.token_prefix}_#{uid}"
      end

      def refresh_key(auth_id, uid)
        "#{JWTSessions::token_prefix}refresh_#{auth_id}_#{uid}"
      end
    end
  end
end
