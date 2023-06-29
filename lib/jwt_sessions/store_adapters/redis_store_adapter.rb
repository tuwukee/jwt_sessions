# frozen_string_literal: true

module JWTSessions
  module StoreAdapters
    class RedisStoreAdapter < AbstractStoreAdapter
      attr_reader :prefix, :storage

      REFRESH_KEYS = %i[csrf access_uuid access_expiration expiration].freeze

      def initialize(token_prefix: JWTSessions.token_prefix, **options)
        @prefix = token_prefix

        begin
          require "redis"
          @storage = configure_redis_client(**options)
        rescue LoadError => e
          msg = "Could not load the 'redis' gem, please add it to your gemfile or " \
                "configure a different adapter (e.g. JWTSessions.store_adapter = :memory)"
          raise e.class, msg, e.backtrace
        end
      end

      def fetch_access(uuid)
        csrf = storage.get(access_key(uuid))
        csrf.nil? ? {} : { csrf: csrf }
      end

      def persist_access(uuid, csrf, expiration)
        key = access_key(uuid)
        storage.set(key, csrf)
        storage.expireat(key, expiration)
      end

      def fetch_refresh(uuid, namespace, first_match = false)
        key    = first_match ? first_refresh_key(uuid) : full_refresh_key(uuid, namespace)
        values = storage.hmget(key, *REFRESH_KEYS).compact

        return {} if values.length != REFRESH_KEYS.length
        REFRESH_KEYS.each_with_index.each_with_object({}) { |(key, index), acc| acc[key] = values[index] }
      end

      def persist_refresh(uuid:, access_expiration:, access_uuid:, csrf:, expiration:, namespace: nil)
        key = full_refresh_key(uuid, namespace)
        update_refresh(
          uuid: uuid,
          access_expiration: access_expiration,
          access_uuid: access_uuid,
          csrf: csrf,
          namespace: namespace
        )
        storage.hset(key, :expiration, expiration)
        storage.expireat(key, expiration)
      end

      def update_refresh(uuid:, access_expiration:, access_uuid:, csrf:, namespace: nil)
        storage.hmset(
          full_refresh_key(uuid, namespace),
          :csrf, csrf,
          :access_expiration, access_expiration,
          :access_uuid, access_uuid
        )
      end

      def all_refresh_tokens(namespace)
        keys_in_namespace = storage.keys(refresh_key("*", namespace))
        (keys_in_namespace || []).each_with_object({}) do |key, acc|
          uuid = uuid_from_key(key)
          acc[uuid] = fetch_refresh(uuid, namespace)
        end
      end

      def destroy_refresh(uuid, namespace)
        key = full_refresh_key(uuid, namespace)
        storage.del(key)
      end

      def destroy_access(uuid)
        storage.del(access_key(uuid))
      end

      private

      def configure_redis_client(redis_url: nil, redis_host: nil, redis_port: nil, redis_db_name: nil, redis_password: nil, redis_cluster: false)
        if redis_url && (redis_host || redis_port || redis_db_name)
          raise ArgumentError, "redis_url cannot be passed along with redis_host, redis_port or redis_db_name options"
        end

        redis_url ||= build_redis_url(
          redis_host: redis_host,
          redis_port: redis_port,
          redis_db_name: redis_db_name
        )

        config = if redis_cluster
                   { cluster: redis_url.split(','),
                     password: redis_password }
                 else
                   { url: redis_url }
                 end

        Redis.new(config)
      end

      def build_redis_url(redis_host: nil, redis_port: nil, redis_db_name: nil)
        redis_db_name ||= JWTSessions.redis_db_name
        return URI.join(JWTSessions.redis_url, redis_db_name).to_s if JWTSessions.redis_url

        redis_host ||= JWTSessions.redis_host
        redis_port ||= JWTSessions.redis_port

        redis_base_url = ENV["REDIS_URL"] || "redis://#{redis_host}:#{redis_port}"
        URI.join(redis_base_url, redis_db_name).to_s
      end

      def full_refresh_key(uuid, namespace)
        "#{prefix}_#{namespace}_refresh_#{uuid}"
      end

      def first_refresh_key(uuid)
        key = full_refresh_key(uuid, "*")
        (storage.keys(key) || []).first
      end

      def refresh_key(uuid, namespace)
        namespace = "*" if namespace.to_s.empty?
        full_refresh_key(uuid, namespace)
      end

      def access_key(uuid)
        "#{prefix}_access_#{uuid}"
      end

      def uuid_from_key(key)
        key.split("_").last
      end
    end
  end
end
