# frozen_string_literal: true

module JWTSessions
  module StoreAdapters
    class MemoryStoreAdapter < AbstractStoreAdapter
      def initialize(options)
        raise ArgumentError, "Memory store doesn't support any options" if options.any?
        @storage = Hash.new { |h, k| h[k] = {} }
      end

      def fetch_access(uid)
        access_token = get_value_if_not_expired(access_key(uid))
        access_token.empty? ? {} : { csrf: access_token[:csrf] }
      end

      def persist_access(uid, csrf, expiration)
        key = access_key(uid)
        access_token = { csrf: csrf, expiration: expiration }
        @storage.store(key, access_token)
      end

      def fetch_refresh(uid, namespace)
        namespaced_key = refresh_key(uid, namespace)
        get_value_if_not_expired(namespaced_key)
      end

      def persist_refresh(uid:, access_expiration:, access_uid:, csrf:, expiration:, namespace: '')
        update_refresh_fields(
          refresh_key(uid, namespace),
          csrf: csrf,
          access_expiration: access_expiration,
          access_uid: access_uid,
          expiration: expiration
        )
      end

      def update_refresh(uid:, access_expiration:, access_uid:, csrf:, namespace: '')
        update_refresh_fields(
          refresh_key(uid, namespace),
          csrf: csrf,
          access_expiration: access_expiration,
          access_uid: access_uid
        )
      end

      def all_refresh_tokens(namespace)
        regex = Regexp.new(
          "^#{refresh_key('*', namespace)}$".
          gsub(/([+|()])/, '\\\\\1').
          gsub(/([^\\])\?/, '\\1.').
          gsub(/([^\\])\*/, '\\1.*')
        )

        keys_in_namespace = @storage.keys.grep(regex)

        (keys_in_namespace || []).each_with_object({}) do |key, acc|
          uid = uid_from_key(key)
          acc[uid] = fetch_refresh(uid, namespace)
        end
      end

      def destroy_refresh(uid, namespace)
        @storage.delete(refresh_key(uid, namespace))
      end

      def destroy_access(uid)
        @storage.delete(access_key(uid))
      end

      private

      def get_value_if_not_expired(key)
        @storage.reject! { |_, value| value[:expiration] && value[:expiration] < Time.now.to_i }
        @storage[key]
      end

      def update_refresh_fields(key, fields)
        updated_refresh = get_value_if_not_expired(key).merge(fields)
        @storage.store(key, updated_refresh)
      end

      def access_key(uid)
        "access_#{uid}"
      end

      def refresh_key(uid, namespace)
        "#{namespace}_refresh_#{uid}"
      end

      def uid_from_key(key)
        key.split('_').last
      end
    end
  end
end
