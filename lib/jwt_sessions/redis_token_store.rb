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

    def fetch_refresh(uid, namespace)
      keys   = %i[csrf access_uid access_expiration expiration]
      values = store.hmget(refresh_key(uid, namespace), *keys).compact
      return {} if values.length != keys.length
      keys.each_with_index.each_with_object({}) { |(key, index), acc| acc[key] = values[index]; }
    end

    def persist_refresh(uid, access_expiration, access_uid, csrf, expiration, namespace = nil)
      ns = namespace || ''
      key = refresh_key(uid, ns)
      update_refresh(uid, access_expiration, access_uid, csrf, ns)
      store.hset(key, :expiration, expiration)
      store.expireat(key, expiration)
    end

    def update_refresh(uid, access_expiration, access_uid, csrf, namespace = nil)
      store.hmset(refresh_key(uid, namespace),
                  :csrf, csrf,
                  :access_expiration, access_expiration,
                  :access_uid, access_uid)
    end

    def all_in_namespace(namespace)
      keys = store.keys(refresh_key('*', namespace))
      (keys || []).each_with_object({}) do |key, acc|
        uid = uid_from_key(key)
        acc[uid] = fetch_refresh(uid, namespace)
      end
    end

    def destroy_refresh(uid, namespace)
      store.del(refresh_key(uid, namespace))
    end

    def destroy_access(uid)
      store.del(access_key(uid))
    end

    private

    def access_key(uid)
      "#{prefix}_access_#{uid}"
    end

    def refresh_key(uid, namespace = nil)
      if namespace
        "#{prefix}_#{namespace}_refresh_#{uid}"
      else
        wildcard_refresh_key(uid)
      end
    end

    def wildcard_refresh_key(uid)
      keys = store.keys(refresh_key(uid, '*')) || []
      keys.first
    end

    def uid_from_key(key)
      key.split('_').last
    end
  end
end
