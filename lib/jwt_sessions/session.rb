# frozen_string_literal: true

module JWTSessions
  class Session
    attr_reader :access_token, :refresh_token, :csrf_token
    attr_accessor :payload, :store

    def initialize(payload = {}, store = JWTSessions.token_store)
      @store   = store
      @payload = payload
    end

    def login
      create_csrf_token
      create_access_token
      create_refresh_token

      tokens_hash
    end

    def masked_csrf(uid)
      csrf = store.fetch_access(uid)
      raise Errors::Unauthorized, 'Access token not found' if csrf.nil?
      CSRFToken.new(csrf).token
    end

    def refresh(refresh_token, &block)
      uid = JWTSessions::Token.decode(refresh_token).first['uid']
      refresh_by_uid(uid, &block)
    end

    def refresh_by_uid(uid, &block)
      retrieve_refresh_token(uid)
      check_refresh_on_time(&block) if block_given?

      AccessToken.destroy(@_refresh.access_uid, store)

      issue_tokens_after_refresh
    end

    private

    def retrieve_refresh_token(uid)
      @_refresh = RefreshToken.find(uid, store)
    end

    def tokens_hash
      { csrf: csrf_token, access: access_token, refresh: refresh_token }
    end

    def check_refresh_on_time
      expiration = @_refresh.access_expiration
      yield @_refresh.uid, expiration if expiration > Time.now
    end

    def issue_tokens_after_refresh
      create_csrf_token
      create_access_token
      update_refresh_token

      tokens_hash
    end

    def update_refresh_token
      @_refresh.update(@_access.uid, @_access.expiration, @_csrf.encoded)
      @refresh_token = @_refresh.token
    end

    def create_csrf_token
      @_csrf = CSRFToken.new
      @csrf_token = @_csrf.token
    end

    def create_refresh_token
      @_refresh = RefreshToken.create(@_csrf.encoded, @_access.uid, @_access.expiration, store)
      @refresh_token = @_refresh.token
    end

    def create_access_token
      @_access = AccessToken.create(@_csrf.encoded, payload, store)
      @access_token = @_access.token
    end
  end
end
