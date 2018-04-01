# frozen_string_literal: true

require 'redis'

module JWTSessions
  class RedisTokenStore
    class << self
      def instance(redis_host, redis_port, redis_db_name, prefix)
        @_tokens_store ||= Redis.new(url: "redis://#{redis_host}:#{redis_port}/#{redis_db_name}")
        @_token_prefix ||= prefix

        new(@_tokens_store, @_token_prefix)
      end

      def clear
        @_tokens_store = nil
        @_token_prefix = nil
      end

      private

      def new(store, prefix)
        super(store, prefix)
      end
    end

    attr_reader :store, :prefix

    def initialize(store, prefix)
      @store  = store
      @prefix = prefix
    end

    def fetch_access(uid)
      csrf = store.get(access_key(uid))
      return {} if csrf.nil?
      { csrf: csrf }
    end

    def persist_access(uid, csrf, expiration)
      key = access_key(uid)
      store.set(key, csrf)
      store.expireat(key, expiration)
    end

    def fetch_refresh(uid)
      keys   = [:csrf, :access_uid, :access_expiration, :expiration]
      values = store.hmget(refresh_key(uid), *keys)
      return {} if values.empty?
      keys.each_with_index.inject({}) { |acc, (key, index)| acc[key] = values[index]; acc }
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
