module JWTSessions
  class AccessToken
    attr_reader :token, :payload, :uid, :expiration, :csrf

    def initialize(csrf, payload, store, uid = SecureRandom.uuid, expiration = JWTSessions.access_expiration)
      @csrf       = csrf
      @uid        = uid
      @expiration = expiration
      @payload    = payload
      @token      = Token.encode(payload.merge(uid: uid, exp: expiration.to_i))
    end

    def destroy
      store.destroy_access(uid)
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
