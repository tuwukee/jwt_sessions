module JWTSessions
  class AccessToken
    attr_reader :token, :payload, :uid, :expiration, :token, :auth_id, :csrf

    def initialize(auth_id, csrf, payload, uid = nil, expiration = nil)
      @auth_id    = auth_id
      @csrf       = csrf
      @uid        = uid || SecureRandom.uuid
      @expiration = expiration || JWTSessions.access_expiration
      @payload    = payload
      @token      = Token.encode(payload.merge(token_uid: uid, exp: expiration))
    end

    class << self
      def create(auth_id, csrf, payload)
        new(auth_id, csrf, payload).tap do |inst|
          TokenStore.set_access(inst.uid, { auth_id: inst.auth_id, csrf: inst.csrf, expiration: inst.expiration })
        end
      end

      def destroy(uid)
        TokenStore.destroy_access(uid)
      end
    end
  end
end
