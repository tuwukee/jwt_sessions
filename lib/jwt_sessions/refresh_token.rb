# frozen_string_literal: true

module JWTSessions
  class RefreshToken
    attr_reader :expiration, :uid, :token, :auth_id, :csrf, :access_uid, :access_expiration

    def initialize(auth_id, csrf, access_uid, access_expiration, uid = nil, expiration = nil)
      @auth_id           = auth_id
      @csrf              = csrf
      @access_uid        = access_uid
      @access_expiration = access_expiration
      @uid               = uid || SecureRandom.uuid
      @expiration        = expiration || JWTSessions.refresh_expiration
      @token             = Token.encode(uid: uid, exp: expiration.to_i)
    end

    class << self
      def all(auth_id)
        TokenStore.all_refresh_tokens(auth_id).map do |uid, token_attrs|
          new(auth_id, token_attrs[:csrf], token_attrs[:access_uid], token_attrs[:access_expiration], uid, token_attrs[:expiration])
        end
      end

      def create(auth_id, csrf, access_uid, access_expiration)
        inst = new(auth_id, csrf, access_uid, access_expiration)
        inst.send(:persist_in_store, auth_id,
                                     inst.uid,
                                     csrf,
                                     access_uid,
                                     access_expiration,
                                     inst.expiration)
        inst
      end

      def find(auth_id, uid)
        token_attrs = TokenStore.get_refresh(auth_id, uid)
        raise Errors::Unauthorized, 'Refresh token not found' if token_attrs.empty?
        new(auth_id, token_attrs[:csrf], token_attrs[:access_uid], token_attrs[:access_expiration], uid, token_attrs[:expiration])
      end
    end

    def update_token(access_uid, access_expiration, csrf)
      TokenStore.update_refresh(auth_id, uid, access_uid, access_expiration, csrf)
    end

    def destroy
      TokenStore.destroy_refresh(uid)
    end

    private

    def persist_in_store(auth_id, csrf, access_uid, access_expiration, uid, expiration)
      token = {
        auth_id:           auth_id,
        access_expiration: access_expiration,
        expiration:        expiration,
        csrf:              csrf,
        access_uid:        access_uid
      }
      TokenStore.set_refresh(auth_id, uid, token)
    end
  end
end
