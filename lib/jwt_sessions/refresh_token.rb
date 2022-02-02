# frozen_string_literal: true

module JWTSessions
  class RefreshToken
    attr_reader :expiration, :uuid, :token, :csrf, :access_uuid, :access_expiration, :store, :namespace

    def initialize(csrf,
                   access_uuid,
                   access_expiration,
                   store,
                   options = {})
      @csrf              = csrf
      @access_uuid       = access_uuid
      @access_expiration = access_expiration
      @store             = store
      @uuid              = options.fetch(:uuid, nil) || SecureRandom.uuid
      @expiration        = options.fetch(:expiration, nil) || JWTSessions.refresh_expiration
      @namespace         = options.fetch(:namespace, nil)
      @token             = Token.encode(options.fetch(:payload, {}).merge("uuid" => uuid, "exp" => expiration.to_i))
    end

    class << self
      def create(csrf, access_uuid, access_expiration, store, payload, namespace, expiration = JWTSessions.refresh_expiration)
        inst = new(
          csrf,
          access_uuid,
          access_expiration,
          store,
          payload: payload,
          namespace: namespace,
          expiration: expiration
        )
        inst.send(:persist_in_store)
        inst
      end

      def all(namespace, store)
        tokens = store.all_refresh_tokens(namespace)
        tokens.map do |uuid, token_attrs|
          build_with_token_attrs(store, uuid, token_attrs, namespace)
        end
      end

      # first_match should be set to true when
      # we need to search through the all namespaces
      def find(uuid, store, namespace = nil, first_match: false)
        token_attrs = store.fetch_refresh(uuid, namespace, first_match)
        raise Errors::Unauthorized, "Refresh token not found" if token_attrs.empty?
        build_with_token_attrs(store, uuid, token_attrs, namespace)
      end

      def destroy(uuid, store, namespace)
        store.destroy_refresh(uuid, namespace)
      end

      private

      def build_with_token_attrs(store, uuid, token_attrs, namespace)
        new(
          token_attrs[:csrf],
          token_attrs[:access_uuid],
          token_attrs[:access_expiration],
          store,
          namespace: namespace,
          payload: {},
          uuid: uuid,
          expiration: token_attrs[:expiration]
        )
      end
    end

    def update(access_uuid, access_expiration, csrf)
      @csrf              = csrf
      @access_uuid       = access_uuid
      @access_expiration = access_expiration
      store.update_refresh(
        uuid: uuid,
        access_expiration: access_expiration,
        access_uuid: access_uuid,
        csrf: csrf,
        namespace: namespace
      )
    end

    def destroy
      store.destroy_refresh(uuid, namespace)
    end

    private

    def persist_in_store
      store.persist_refresh(
        uuid: uuid,
        access_expiration: access_expiration,
        access_uuid: access_uuid,
        csrf: csrf,
        expiration: expiration,
        namespace: namespace
      )
    end
  end
end
