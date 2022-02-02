# frozen_string_literal: true

module JWTSessions
  class AccessToken
    attr_reader :payload, :uuid, :expiration, :csrf, :store

    def initialize(csrf, payload, store, uuid = SecureRandom.uuid, expiration = JWTSessions.access_expiration)
      @csrf       = csrf
      @uuid       = uuid
      @expiration = expiration
      @payload    = payload.merge("uuid" => uuid, "exp" => expiration.to_i)
      @store      = store
    end

    def destroy
      store.destroy_access(uuid)
    end

    def refresh_uuid=(uuid)
      self.payload["ruuid"] = uuid
    end

    def refresh_uuid
      payload["ruuid"]
    end

    def token
      Token.encode(payload)
    end

    class << self
      def create(csrf, payload, store, expiration = JWTSessions.access_expiration)
        new(csrf, payload, store, SecureRandom.uuid, expiration).tap do |inst|
          store.persist_access(inst.uuid, inst.csrf, inst.expiration)
        end
      end

      def destroy(uuid, store)
        store.destroy_access(uuid)
      end

      # AccessToken's find method cannot be used to retrieve token's payload
      # or any other information but is intended to identify if the token is present
      # and to retrieve session's CSRF token
      def find(uuid, store)
        token_attrs = store.fetch_access(uuid)
        raise Errors::Unauthorized, "Access token not found" if token_attrs.empty?
        build_with_token_attrs(store, uuid, token_attrs)
      end

      private

      def build_with_token_attrs(store, uuid, token_attrs)
        new(token_attrs[:csrf], {}, store, uuid)
      end
    end
  end
end
