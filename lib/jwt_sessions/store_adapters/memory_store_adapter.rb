# frozen_string_literal: true

module JWTSessions
  module StoreAdapters
    class MemoryStoreAdapter < AbstractStoreAdapter
      attr_reader :storage

      def initialize(options)
        raise ArgumentError, "Memory store doesn't support any options" if options.any?
        @storage = Hash.new do |h, k|
          h[k] = Hash.new { |hh, kk| hh[kk] = {} }
        end
      end

      def fetch_access(uid)
        access_token = value_if_not_expired(uid, "access", "")
        access_token.empty? ? {} : { csrf: access_token[:csrf] }
      end

      def persist_access(uid, csrf, expiration)
        access_token = { csrf: csrf, expiration: expiration }
        storage[""]["access"].store(uid, access_token)
      end

      def fetch_refresh(uid, namespace, first_match = false)
        if first_match
          storage.keys.each do |namespace_key|
            val = value_if_not_expired(uid, "refresh", namespace_key)
            return val unless val.empty?
          end
          {}
        else
          value_if_not_expired(uid, "refresh", namespace.to_s)
        end
      end

      def persist_refresh(uid:, access_expiration:, access_uid:, csrf:, expiration:, namespace: "")
        update_refresh_fields(
          uid,
          namespace.to_s,
          csrf: csrf,
          access_expiration: access_expiration,
          access_uid: access_uid,
          expiration: expiration
        )
      end

      def update_refresh(uid:, access_expiration:, access_uid:, csrf:, namespace: "")
        update_refresh_fields(
          uid,
          namespace.to_s,
          csrf: csrf,
          access_expiration: access_expiration,
          access_uid: access_uid
        )
      end

      def all_refresh_tokens(namespace)
        namespace_keys = namespace.nil? ? storage.keys : [namespace]

        namespace_keys.each_with_object({}) do |namespace_key, acc|
          select_keys(storage[namespace_key]["refresh"], acc)
        end
      end

      def destroy_refresh(uid, namespace)
        storage[namespace.to_s]["refresh"].delete(uid)
      end

      def destroy_access(uid)
        storage[""]["access"].delete(uid)
      end

      private

      def value_if_not_expired(key, token_type, namespace)
        storage[namespace][token_type].reject! { |_, value| value[:expiration] && value[:expiration] < Time.now.to_i }
        storage[namespace][token_type][key] || {}
      end

      def update_refresh_fields(key, namespace, fields)
        updated_refresh = value_if_not_expired(key, "refresh", namespace).merge(fields)
        storage[namespace]["refresh"].store(key, updated_refresh)
      end

      def select_keys(keys_hash, acc)
        keys_hash.keys.each do |uid|
          value = keys_hash[uid]
          if value[:expiration] && value[:expiration] < Time.now.to_i
            keys_hash.delete(key)
          else
            acc[uid] = value
          end
        end

        acc
      end
    end
  end
end
