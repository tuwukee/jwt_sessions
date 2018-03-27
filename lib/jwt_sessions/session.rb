# frozen_string_literal: true

module JWTSessions
  class Session
    attr_reader :access_token, :refresh_token, :csrf_token
    attr_accessor :payload, :auth_id

    # auth_id is a unique identifier of a token issuer aka user
    def initialize(auth_id, payload = {})
      @auth_id = auth_id
      @payload = payload
    end

    def login
      create_csrf_token
      create_access_token
      create_refresh_token

      tokens_hash
    end

    def masked_csrf(refresh_payload)
      token = retrieve_refresh_token(refresh_payload)
      CSRFToken.new(token.csrf).token
    end

    def all
      RefreshToken.all(auth_id)
    end

    def refresh(refresh_payload, &block)
      retrieve_refresh_token
      check_refresh_on_time(&block) if block_given?

      AccessToken.destroy(@_refresh.access_token_id)

      issue_tokens_after_refresh
    end

    private

    def retrieve_refresh_token(payload)
      uid = refresh_payload['token_uid']
      @_refresh = RefreshToken.find(uid, auth_id)
      raise Errors::Unauthorized unless @_refresh
      @_refresh
    end

    def tokens_hash
      { csrf: csrf_token, access: access_token, refresh: refresh_token }
    end

    def check_refresh_on_time
      expiration = @_refresh.access_expiration
      yield @_refresh.uid, auth_id, expiration if expiration > Time.now
    end

    def issue_tokens_after_refresh
      create_csrf_token
      create_access_token
      update_refresh_token

      tokens_hash
    end

    def update_refresh_token
      @_refresh.update_token(@_access.uid, @_access.expiration, @_csrf.encoded)
      @refresh_token = @_refresh.token
    end

    def create_csrf_token
      @_csrf = CSRFToken.new
      @csrf_token = @_csrf.token
    end

    def craete_refresh_token
      @_refresh = RefreshToken.create(auth_uid, @_csrf.encoded, @_access.uid, @_access.expiration)
      @refresh_token = @_refresh.token
    end

    def create_access_token
      @_access = AccessToken.create(auth_id, @_csrf.encoded, payload)
      @access_token = @_access.token
    end
  end
end
