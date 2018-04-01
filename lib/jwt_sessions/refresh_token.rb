# frozen_string_literal: true

module JWTSessions
  class RefreshToken
    attr_reader :expiration, :uid, :token, :csrf, :access_uid, :access_expiration, :store

    def initialize(csrf, access_uid, access_expiration, store, uid = SecureRandom.uuid, expiration = JWTSessions.refresh_expiration)
      @csrf              = csrf
      @access_uid        = access_uid
      @access_expiration = access_expiration
      @uid               = uid
      @expiration        = expiration
      @store             = store
      @token             = Token.encode(uid: uid, exp: expiration.to_i)
    end

    class << self
      def create(csrf, access_uid, access_expiration, store)
        inst = new(csrf, access_uid, access_expiration, store)
        inst.send(:persist_in_store)
        inst
      end

      def find(uid, store)
        token_attrs = store.fetch_refresh(uid)
        raise Errors::Unauthorized, 'Refresh token not found' if token_attrs.empty?
        new(token_attrs[:csrf],
            token_attrs[:access_uid],
            token_attrs[:access_expiration],
            store,
            uid,
            token_attrs[:expiration])
      end

      def destroy(uid, store)
        store.destroy_refresh(uid)
      end
    end

    def update(access_uid, access_expiration, csrf)
      store.update_refresh(uid, access_uid, access_expiration, csrf)
    end

    def destroy
      store.destroy_refresh(uid)
    end

    private

    def persist_in_store
      store.persist_refresh(uid, access_expiration, access_uid, csrf, expiration)
    end
  end
end
