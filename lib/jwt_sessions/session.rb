# frozen_string_literal: true

module JWTSessions
  class Session
    attr_reader :access_token, :refresh_token, :csrf_token
    attr_accessor :payload, :store, :refresh_payload

    def initialize(options = {})
      @store           = options.fetch(:store, JWTSessions.token_store)
      @refresh_payload = options.fetch(:refresh_payload, {})
      @payload         = options.fetch(:payload, {})
      @access_claims   = options.fetch(:access_claims, {})
      @refresh_claims  = options.fetch(:refresh_claims, {})
    end

    def login
      create_csrf_token
      create_access_token
      create_refresh_token

      tokens_hash
    end

    def valid_csrf?(token, csrf_token, token_type = :access)
      send(:"valid_#{token_type}_csrf?", token, csrf_token)
    end

    def masked_csrf(access_token)
      csrf(access_token).token
    end

    def refresh(refresh_token, &block)
      refresh_token_data(refresh_token)
      refresh_by_uid(&block)
    end

    private

    def valid_access_csrf?(access_token, csrf_token)
      csrf(access_token).valid_authenticity_token?(csrf_token)
    end

    def valid_refresh_csrf?(refresh_token, csrf_token)
      refresh_csrf(refresh_token).valid_authenticity_token?(csrf_token)
    end

    def refresh_by_uid(&block)
      check_refresh_on_time(&block) if block_given?
      AccessToken.destroy(@_refresh.access_uid, store)
      issue_tokens_after_refresh
    end

    def csrf(access_token)
      token_data = access_token_data(access_token)
      raise Errors::Unauthorized, 'Access token not found' if token_data.empty?
      CSRFToken.new(token_data[:csrf])
    end

    def refresh_csrf(refresh_token)
      refresh_token_instance = refresh_token_data(refresh_token)
      CSRFToken.new(refresh_token_instance.csrf)
    end

    def access_token_data(token)
      uid = token_uid(token, :access, @access_claims)
      store.fetch_access(uid)
    end

    def refresh_token_data(token)
      uid = token_uid(token, :refresh, @refresh_claims)
      retrieve_refresh_token(uid)
    end

    def token_uid(token, type, claims)
      token_payload = JWTSessions::Token.decode(token, claims).first
      uid           = token_payload.fetch('uid', nil)
      if uid.nil?
        message = "#{type.to_s.capitalize} token payload does not contain token uid"
        raise Errors::InvalidPayload, message
      end
      uid
    end

    def retrieve_refresh_token(uid)
      @_refresh = RefreshToken.find(uid, store)
    end

    def tokens_hash
      { csrf: csrf_token,
        access: access_token,
        access_expires_at: Time.at(@_access.expiration.to_i),
        refresh: refresh_token,
        refresh_expires_at: Time.at(@_refresh.expiration.to_i) }
    end

    def check_refresh_on_time
      expiration = @_refresh.access_expiration
      yield @_refresh.uid, expiration if expiration.to_i > Time.now.to_i
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
      @_refresh = RefreshToken.create(@_csrf.encoded,
                                      @_access.uid,
                                      @_access.expiration,
                                      store,
                                      @refresh_payload)
      @refresh_token = @_refresh.token
    end

    def create_access_token
      @_access = AccessToken.create(@_csrf.encoded, payload, store)
      @access_token = @_access.token
    end
  end
end
