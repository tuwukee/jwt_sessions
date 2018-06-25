# frozen_string_literal: true

module JWTSessions
  class AccessToken
    attr_reader :payload, :uid, :expiration, :csrf, :store

    def initialize(csrf, payload, store, uid = SecureRandom.uuid, expiration = JWTSessions.access_expiration)
      @csrf       = csrf
      @uid        = uid
      @expiration = expiration
      @payload    = payload.merge('uid' => uid, 'exp' => expiration.to_i)
      @store      = store
    end

    def destroy
      store.destroy_access(uid)
    end

    def refresh_uid=(uid)
      self.payload['ruid'] = uid
    end

    def refresh_uid
      payload['ruid']
    end

    def token
      Token.encode(payload)
    end

    class << self
      def create(csrf, payload, store)
        new(csrf, payload, store).tap do |inst|
          store.persist_access(inst.uid, inst.csrf, inst.expiration)
        end
      end

      def destroy(uid, store)
        store.destroy_access(uid)
      end

      # AccessToken's find method cannot be used to retrieve token's payload
      # or any other information but is intended to identify if the token is present
      # and to retrieve session's CSRF token
      def find(uid, store)
        token_attrs = store.fetch_access(uid)
        raise Errors::Unauthorized, 'Access token not found' if token_attrs.empty?
        build_with_token_attrs(store, uid, token_attrs)
      end

      private

      def build_with_token_attrs(store, uid, token_attrs)
        new(token_attrs[:csrf], {}, store, uid)
      end
    end
  end
end
