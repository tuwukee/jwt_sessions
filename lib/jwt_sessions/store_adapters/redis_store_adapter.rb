# frozen_string_literal: true

require "pry"

module JWTSessions
  module StoreAdapters
    class RedisStoreAdapter < AbstractStoreAdapter
      attr_reader :prefix, :redis_client

      def initialize(token_prefix: JWTSessions.token_prefix, **options)
        @prefix = token_prefix

        begin
          require 'redis'
          @redis_client = configure_redis_client(options)
        rescue LoadError => e
          msg = "Could not load the 'redis' gem, please add it to your gemfile or " \
                "configure a different adapter (e.g. JWTSessions.store_adapter = :memory)"
          raise e.class, msg, e.backtrace
        end
      end

      def fetch_access(uid)
        csrf = @redis_client.get(access_key(uid))
        csrf.nil? ? {} : { csrf: csrf }
      end

      def persist_access(uid, csrf, expiration)
        key = access_key(uid)
        @redis_client.set(key, csrf)
        @redis_client.expireat(key, expiration)
      end

      REFRESH_KEYS = %i[csrf access_uid access_expiration expiration].freeze

      def fetch_refresh(uid, namespace)
        values = @redis_client.hmget(refresh_key(uid, namespace), *REFRESH_KEYS).compact

        return {} if values.length != REFRESH_KEYS.length
        REFRESH_KEYS.each_with_index.each_with_object({}) { |(key, index), acc| acc[key] = values[index] }
      end

      def persist_refresh(uid:, access_expiration:, access_uid:, csrf:, expiration:, namespace: nil)
        puts 'persist refresh'
        key = refresh_key(uid, namespace)
        puts "uid: #{uid}, access_uid: #{access_uid}"
        update_refresh(
          uid: uid,
          access_expiration: access_expiration,
          access_uid: access_uid,
          csrf: csrf,
          namespace: namespace
        )
        @redis_client.hset(key, :expiration, expiration)
        @redis_client.expireat(key, expiration)
      end

      def update_refresh(uid:, access_expiration:, access_uid:, csrf:, namespace: nil)
        puts 'update refresh'
        puts "uid: #{uid}, access_uid: #{access_uid}"
        @redis_client.hmset(
          refresh_key(uid, namespace),
          :csrf, csrf,
          :access_expiration, access_expiration,
          :access_uid, access_uid
        )
      end

      def all_refresh_tokens(namespace = nil)
        puts refresh_key('*', namespace)
        keys_in_namespace = @redis_client.keys(refresh_key('*', namespace))
        (keys_in_namespace || []).each_with_object({}) do |key, acc|
          uid = uid_from_key(key)
          acc[uid] = fetch_refresh(uid, namespace)
        end
      end

      def destroy_refresh(uid, namespace)
        @redis_client.del(refresh_key(uid, namespace))
      end

      def destroy_access(uid)
        @redis_client.del(access_key(uid))
      end

      private

      def configure_redis_client(redis_url: nil, redis_host: nil, redis_port: nil, redis_db_name: nil)
        if redis_url && (redis_host || redis_port || redis_db_name)
          raise ArgumentError, 'redis_url cannot be passed along with redis_host, redis_port or redis_db_name options'
        end

        redis_url ||= build_redis_url(
          redis_host: redis_host,
          redis_port: redis_port,
          redis_db_name: redis_db_name
        )

        Redis.new(url: redis_url)
      end

      def build_redis_url(redis_host: nil, redis_port: nil, redis_db_name: nil)
        redis_db_name ||= JWTSessions.redis_db_name
        return URI.join(JWTSessions.redis_url, redis_db_name).to_s if JWTSessions.redis_url

        redis_host ||= JWTSessions.redis_host
        redis_port ||= JWTSessions.redis_port

        redis_base_url = ENV['REDIS_URL'] || "redis://#{redis_host}:#{redis_port}"
        URI.join(redis_base_url, redis_db_name).to_s
      end

      def refresh_key(uid, namespace)
        if namespace.to_s.empty?
          "#{prefix}_*_refresh_#{uid}"
        else
          "#{prefix}_#{namespace}_refresh_#{uid}"
        end
        #if namespace
        #  "#{prefix}_#{namespace}_refresh_#{uid}"
        #else
        #  wildcard_refresh_key(uid)
        #end
      end

      def wildcard_refresh_key(uid)
        (@redis_client.keys(refresh_key(uid, '*')) || []).first
      end

      def access_key(uid)
        "#{prefix}_access_#{uid}"
      end

      def uid_from_key(key)
        key.split('_').last
      end
    end
  end
end
