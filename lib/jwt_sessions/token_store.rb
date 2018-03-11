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

      def set_refresh(token)
        refresh_key = "#{JWTSessions::token_prefix}refresh_#{token[:uid]}"
        instance.hmset(refresh_key,
                       :expires_at, token[:expires_at],
                       :salt, token[:salt],
                       :uid, token[:uid])
        instance.expireat(refresh_key, token[:expires_at].to_i)
      end

      def get_refresh(uid)
        instance.hmget("#{JWTSessions::token_prefix}refresh_#{uid}", :expires_at, :salt, :uid)
      end

      def destroy_refresh(uid)
        instance.del("#{JWTSessions::token_prefix}refresh_#{uid}")
      end
    end
  end
end
