# frozen_string_literal: true

module JWTSessions
  class AccessToken
    attr_reader :payload, :uid, :expiration, :csrf, :store

    def initialize(csrf, payload, store, uid = SecureRandom.uuid, expiration = JWTSessions.access_expiration)
      @csrf       = csrf
      @uid        = uid
      @expiration = expiration
      @payload    = payload.merge(uid: uid, exp: expiration.to_i)
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
    end
  end
end
