# frozen_string_literal: true

require 'redis'

module JWTSessions
  class TokenStore
    class << self
      def instance
        @_tokens_store ||= Redis.new(url: "#{JWTSessions.redis_host}/#{JWTSessions.redis_db_name}")
      end

      def get_csrf(uid)
        instance.get("#{JWTSessions.tokens_prefix}_#{uid}")
      end
    end
  end
end
