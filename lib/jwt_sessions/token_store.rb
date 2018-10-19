# frozen_string_literal: true

module JWTSessions
  class TokenStore

    class << self
      def instance(store_opts)
        @_tokens_store ||= init_token_storage(store_opts)
        new(@_tokens_store)
      end

      def clear
        @_tokens_store.clear
      end

      private

      def new(store)
        super(store)
      end

      def init_token_storage(opts)
        storage_opts = {
            storage: opts[:storage],
            prefix: opts[:prefix]
        }
        StorageAdapter.instance(storage_opts)
      end
    end

    attr_reader :store

    def initialize(store)
      @store = store
    end

    def fetch_access(uid)
      store[access_key(uid)]||{}
    end

    def persist_access(uid, csrf, expiration)
      store.set(access_key(uid), { csrf: csrf }, expires: expiration)
    end

    def fetch_refresh(uid, namespace)
      keys   = %i[csrf access_uid access_expiration expiration]
      values = store.get(namespace, refresh_key(uid), keys)
      return {} if values&.length != keys.length
      keys.each_with_index.each_with_object({}) { |(key, index), acc| acc[key] = values[index]; }
    end

    def persist_refresh(uid, access_expiration, access_uid, csrf, expiration, namespace = nil)
      update_refresh(uid, access_expiration, access_uid, csrf, namespace)
      store.set(refresh_key(uid), { expiration: expiration }, expires: expiration, namespace: namespace)
    end

    def update_refresh(uid, access_expiration, access_uid, csrf, namespace = nil)
      store.set(refresh_key(uid), { csrf: csrf, access_expiration: access_expiration, access_uid: access_uid },
                namespace: namespace )
    end

    def all_in_namespace(namespace)
      store.keys_in(namespace).each_with_object({}) do |key, acc|
        uid = uid_from_key(key)
        acc[uid] = fetch_refresh(uid, namespace)
      end
    end

    def destroy_refresh(uid, namespace)
      store.in_ns(namespace).delete(refresh_key(uid))
    end

    def destroy_access(uid)
      store.delete(access_key(uid))
    end

    private

    def access_key(uid)
      "access_#{uid}"
    end

    def refresh_key(uid)
      "refresh_#{uid}"
    end

    def uid_from_key(key)
      key.split('_').last
    end

  end
end
