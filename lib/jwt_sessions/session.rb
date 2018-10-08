# frozen_string_literal: true

module JWTSessions
  class Session
    attr_reader :access_token,
                :refresh_token,
                :csrf_token

    attr_accessor :payload,
                  :store,
                  :refresh_payload,
                  :namespace,
                  :refresh_by_access_allowed

    def initialize(options = {})
      @store                     = options.fetch(:store, JWTSessions.token_store)
      @refresh_payload           = options.fetch(:refresh_payload, {})
      @payload                   = options.fetch(:payload, {})
      @access_claims             = options.fetch(:access_claims, {})
      @refresh_claims            = options.fetch(:refresh_claims, {})
      @namespace                 = options.fetch(:namespace, nil)
      @refresh_by_access_allowed = options.fetch(:refresh_by_access_allowed, false)
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

    def session_exists?(token, token_type = :access)
      send(:"#{token_type}_token_data", token)
      true
    rescue Errors::Unauthorized
      false
    end

    def masked_csrf(access_token)
      csrf(access_token).token
    end

    def refresh(refresh_token, &block)
      refresh_token_data(refresh_token)
      refresh_by_uid(&block)
    end

    def refresh_by_access_payload(&block)
      raise Errors::InvalidPayload if payload.nil?
      ruid = retrieve_val_from(payload, :access, 'ruid', 'refresh uid')
      retrieve_refresh_token(ruid)

      check_access_uid_within_refresh_token(&block) if block_given?

      refresh_by_uid(&block)
    end

    def flush_by_access_payload
      raise Errors::InvalidPayload if payload.nil?
      ruid = retrieve_val_from(payload, :access, 'ruid', 'refresh uid')
      flush_by_uid(ruid)
    end

    # flush the session by refresh token
    def flush_by_token(token)
      uid = token_uid(token, :refresh, @refresh_claims)
      flush_by_uid(uid)
    end

    # flush the session by refresh token uid
    def flush_by_uid(uid)
      token = retrieve_refresh_token(uid)

      AccessToken.destroy(token.access_uid, store)
      token.destroy
    end

    # flush access tokens only and keep refresh
    def flush_namespaced_access_tokens
      return 0 unless namespace
      tokens = RefreshToken.all(namespace, store)
      tokens.each do |token|
        AccessToken.destroy(token.access_uid, store)
        # unlink refresh token from the current access token
        token.update(nil, nil, token.csrf)
      end.count
    end

    def flush_namespaced
      return 0 unless namespace
      tokens = RefreshToken.all(namespace, store)
      tokens.each do |token|
        AccessToken.destroy(token.access_uid, store)
        token.destroy
      end.count
    end

    def self.flush_all(store = JWTSessions.token_store)
      tokens = RefreshToken.all(nil, store)
      tokens.each do |token|
        AccessToken.destroy(token.access_uid, store)
        token.destroy
      end.count
    end

    def valid_access_request?(external_csrf_token, external_payload)
      ruid = retrieve_val_from(external_payload, :access, 'ruid', 'refresh uid')
      uid  = retrieve_val_from(external_payload, :access, 'uid', 'access uid')

      refresh_token = RefreshToken.find(ruid, JWTSessions.token_store)
      return false unless uid == refresh_token.access_uid

      CSRFToken.new(refresh_token.csrf).valid_authenticity_token?(external_csrf_token)
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
      CSRFToken.new(token_data[:csrf])
    end

    def refresh_csrf(refresh_token)
      refresh_token_instance = refresh_token_data(refresh_token)
      CSRFToken.new(refresh_token_instance.csrf)
    end

    def access_token_data(token)
      uid = token_uid(token, :access, @access_claims)
      data = store.fetch_access(uid)
      raise Errors::Unauthorized, 'Access token not found' if data.empty?
      data
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

    def retrieve_val_from(token_payload, type, val_key, val_name)
      val = token_payload.fetch(val_key, nil)
      if val.nil?
        message = "#{type.to_s.capitalize} token payload does not contain #{val_name}"
        raise Errors::InvalidPayload, message
      end
      val
    end

    def retrieve_refresh_token(uid)
      @_refresh = RefreshToken.find(uid, store, namespace)
    end

    def tokens_hash
      {
        csrf: csrf_token,
        access: access_token,
        access_expires_at: Time.at(@_access.expiration.to_i),
        refresh: refresh_token,
        refresh_expires_at: Time.at(@_refresh.expiration.to_i)
      }
    end

    def refresh_tokens_hash
      {
        csrf: csrf_token,
        access: access_token,
        access_expires_at: Time.at(@_access.expiration.to_i)
      }
    end

    def check_refresh_on_time
      expiration = @_refresh.access_expiration
      return if expiration.size.zero?
      yield @_refresh.uid, expiration if expiration.to_i > Time.now.to_i
    end

    def check_access_uid_within_refresh_token
      uid = retrieve_val_from(payload, :access, 'uid', 'access uid')
      access_uid = @_refresh.access_uid
      return if access_uid.size.zero?
      yield @_refresh.uid, @_refresh.access_expiration if access_uid != uid
    end

    def issue_tokens_after_refresh
      create_csrf_token
      create_access_token
      update_refresh_token

      refresh_tokens_hash
    end

    def update_refresh_token
      @_refresh.update(@_access.uid, @_access.expiration, @_csrf.encoded)
      @refresh_token = @_refresh.token
      link_access_to_refresh
    end

    def link_access_to_refresh
      return unless refresh_by_access_allowed
      @_access.refresh_uid = @_refresh.uid
      @access_token = @_access.token
      @payload = @_access.payload
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
                                      refresh_payload,
                                      namespace)
      @refresh_token = @_refresh.token
      link_access_to_refresh
    end

    def create_access_token
      @_access = AccessToken.create(@_csrf.encoded, payload, store)
      @access_token = @_access.token
    end
  end
end
