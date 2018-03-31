# frozen_string_literal: true

require 'redis'

module JWTSessions
  class RedisTokenStore
    class << self
      def instance(redis_host, redis_port, redis_db_name, prefix)
        @_tokens_store ||= Redis.new(url: "redis://#{rudis_host}:#{redis_port}/#{redis_db_name}")
        @_token_prefix ||= prefix

        new(@_tokens_store, @_tokens_prefix)
      end

      def clear
        @_tokens_store = nil
        @_token_prefix = nil
      end

      private

      def new(store, prefix)
        @store  = store
        @prefix = prefix
      end
    end

    attr_reader :store, :prefix

    def fetch_access(uid)
      store.get(access_key(uid))
    end

    def persist_access(uid, csrf, expiration)
      key = access_key(uid)
      store.set(key, csrf)
      store.expireat(key, expiration)
    end

    def fetch_refresh(uid)
      store.hmget(refresh_key(uid), :access_expiration, :access_uid, :csrf, :expiration)
    end

    def persist_refresh(uid, access_expiration, access_uid, csrf, expiration)
      key = refresh_key(uid)
      update_refresh(uid, access_expiration, access_uid, csrf)
      store.hset(key, :expiration, expiration)
      store.expireat(key, expiration)
    end

    def update_refresh(uid, access_expiration, access_uid, csrf)
      store.hmset(refresh_key(uid), :csrf, csrf, :access_expiration, access_expiration, :access_uid, access_uid)
    end

    def destroy_refresh(uid)
      store.del(refresh_key(uid))
    end

    def destroy_access(uid)
      store.del(access_key(uid))
    end

    private

    def access_key(uid)
      "#{prefix}_access_#{uid}"
    end

    def refresh_key(uid)
      "#{prefix}_refresh_#{uid}"
    end
  end
end
