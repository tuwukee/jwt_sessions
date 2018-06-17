# frozen_string_literal: true

module JWTSessions
  class RefreshToken
    attr_reader :expiration, :uid, :token, :csrf, :access_uid, :access_expiration, :store, :namespace

    def initialize(csrf,
                   access_uid,
                   access_expiration,
                   store,
                   options = {})
      @csrf              = csrf
      @access_uid        = access_uid
      @access_expiration = access_expiration
      @store             = store
      @uid               = options.fetch(:uid, SecureRandom.uuid)
      @expiration        = options.fetch(:expiration, JWTSessions.refresh_expiration)
      @namespace         = options.fetch(:namespace, nil)
      @token             = Token.encode(options.fetch(:payload, {}).merge('uid' => uid, 'exp' => expiration.to_i))
    end

    class << self
      def create(csrf, access_uid, access_expiration, store, payload, namespace)
        inst = new(csrf, access_uid, access_expiration, store, payload: payload, namespace: namespace)
        inst.send(:persist_in_store)
        inst
      end

      def all(namespace, store)
        tokens = store.all_in_namespace(namespace)
        tokens.map do |uid, token_attrs|
          build_with_token_attrs(store, uid, token_attrs, namespace)
        end
      end

      def find(uid, store, namespace = nil)
        token_attrs = store.fetch_refresh(uid, namespace)
        raise Errors::Unauthorized, 'Refresh token not found' if token_attrs.empty?
        build_with_token_attrs(store, uid, token_attrs, namespace)
      end

      def destroy(uid, store, namespace)
        store.destroy_refresh(uid, namespace)
      end

      private

      def build_with_token_attrs(store, uid, token_attrs, namespace)
        new(token_attrs[:csrf],
            token_attrs[:access_uid],
            token_attrs[:access_expiration],
            store,
            namespace: namespace,
            payload: {},
            uid: uid,
            expiration: token_attrs[:expiration])
      end
    end

    def update(access_uid, access_expiration, csrf)
      @csrf              = csrf
      @access_uid        = access_uid
      @access_expiration = access_expiration
      store.update_refresh(uid, access_expiration, access_uid, csrf, namespace)
    end

    def destroy
      store.destroy_refresh(uid, namespace)
    end

    private

    def persist_in_store
      store.persist_refresh(uid, access_expiration, access_uid, csrf, expiration, namespace)
    end
  end
end
