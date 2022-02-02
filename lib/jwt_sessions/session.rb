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
      @_access_exp               = options.fetch(:access_exp, nil)
      @_refresh_exp              = options.fetch(:refresh_exp, nil)
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
      send(:"#{token_type}_token_data", token, true)
      true
    rescue Errors::Unauthorized
      false
    end

    def masked_csrf(access_token)
      csrf(access_token).token
    end

    def refresh(refresh_token, &block)
      refresh_token_data(refresh_token)
      refresh_by_uuid(&block)
    end

    def refresh_by_access_payload(&block)
      raise Errors::InvalidPayload if payload.nil?
      ruuid = retrieve_val_from(payload, :access, "ruuid", "refresh uuid")
      retrieve_refresh_token(ruuid)

      check_access_uuid_within_refresh_token(&block) if block_given?

      refresh_by_uuid(&block)
    end

    def flush_by_access_payload
      raise Errors::InvalidPayload if payload.nil?
      ruuid = retrieve_val_from(payload, :access, "ruuid", "refresh uuid")
      flush_by_uuid(ruuid)
    end

    # flush the session by refresh token
    def flush_by_token(token)
      uuid = token_uuid(token, :refresh, @refresh_claims)
      flush_by_uuid(uuid)
    end

    # flush the session by refresh token uuid
    def flush_by_uuid(uuid)
      token = retrieve_refresh_token(uuid)

      AccessToken.destroy(token.access_uuid, store)
      token.destroy
    end

    # flush access tokens only and keep refresh
    def flush_namespaced_access_tokens
      return 0 unless namespace
      tokens = RefreshToken.all(namespace, store)
      tokens.each do |token|
        AccessToken.destroy(token.access_uuid, store)
        # unlink refresh token from the current access token
        token.update(nil, nil, token.csrf)
      end.count
    end

    def flush_namespaced
      return 0 unless namespace
      tokens = RefreshToken.all(namespace, store)
      tokens.each do |token|
        AccessToken.destroy(token.access_uuid, store)
        token.destroy
      end.count
    end

    def self.flush_all(store = JWTSessions.token_store)
      tokens = RefreshToken.all(nil, store)
      tokens.each do |token|
        AccessToken.destroy(token.access_uuid, store)
        token.destroy
      end.count
    end

    def valid_access_request?(external_csrf_token, external_payload)
      ruuid = retrieve_val_from(external_payload, :access, "ruuid", "refresh uuid")
      uuid  = retrieve_val_from(external_payload, :access, "uuid", "access uuid")

      refresh_token = RefreshToken.find(ruuid, JWTSessions.token_store, first_match: true)
      return false unless uuid == refresh_token.access_uuid

      CSRFToken.new(refresh_token.csrf).valid_authenticity_token?(external_csrf_token)
    end

    private

    def valid_access_csrf?(access_token, csrf_token)
      csrf(access_token).valid_authenticity_token?(csrf_token)
    end

    def valid_refresh_csrf?(refresh_token, csrf_token)
      refresh_csrf(refresh_token).valid_authenticity_token?(csrf_token)
    end

    def refresh_by_uuid(&block)
      check_refresh_on_time(&block) if block_given?
      AccessToken.destroy(@_refresh.access_uuid, store)
      issue_tokens_after_refresh
    end

    def csrf(access_token)
      token_data = access_token_data(access_token)
      CSRFToken.new(token_data[:csrf])
    end

    def refresh_csrf(refresh_token)
      refresh_token_instance = refresh_token_data(refresh_token, true)
      CSRFToken.new(refresh_token_instance.csrf)
    end

    def access_token_data(token, _first_match = false)
      uuid = token_uuid(token, :access, @access_claims)
      data = store.fetch_access(uuid)
      raise Errors::Unauthorized, "Access token not found" if data.empty?
      data
    end

    def refresh_token_data(token, first_match = false)
      uuid = token_uuid(token, :refresh, @refresh_claims)
      retrieve_refresh_token(uuid, first_match: first_match)
    end

    def token_uuid(token, type, claims)
      token_payload = JWTSessions::Token.decode(token, claims).first
      uuid          = token_payload.fetch("uuid", nil)
      if uuid.nil?
        message = "#{type.to_s.capitalize} token payload does not contain token uuid"
        raise Errors::InvalidPayload, message
      end
      uuid
    end

    def retrieve_val_from(token_payload, type, val_key, val_name)
      val = token_payload.fetch(val_key, nil)
      if val.nil?
        message = "#{type.to_s.capitalize} token payload does not contain #{val_name}"
        raise Errors::InvalidPayload, message
      end
      val
    end

    def retrieve_refresh_token(uuid, first_match: false)
      @_refresh = RefreshToken.find(uuid, store, namespace, first_match: first_match)
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
      yield @_refresh.uuid, expiration if expiration.to_i > Time.now.to_i
    end

    def check_access_uuid_within_refresh_token
      uuid = retrieve_val_from(payload, :access, "uuid", "access uuid")
      access_uuid = @_refresh.access_uuid
      return if access_uuid.size.zero?
      yield @_refresh.uuid, @_refresh.access_expiration if access_uuid != uuid
    end

    def issue_tokens_after_refresh
      create_csrf_token
      create_access_token
      update_refresh_token

      refresh_tokens_hash
    end

    def update_refresh_token
      @_refresh.update(@_access.uuid, @_access.expiration, @_csrf.encoded)
      @refresh_token = @_refresh.token
      link_access_to_refresh
    end

    def link_access_to_refresh
      return unless refresh_by_access_allowed
      @_access.refresh_uuid = @_refresh.uuid
      @access_token = @_access.token
      @payload = @_access.payload
    end

    def create_csrf_token
      @_csrf = CSRFToken.new
      @csrf_token = @_csrf.token
    end

    def create_refresh_token
      @_refresh = RefreshToken.create(
        @_csrf.encoded,
        @_access.uuid,
        @_access.expiration,
        store,
        refresh_payload,
        namespace,
        JWTSessions.custom_refresh_expiration(@_refresh_exp)
      )
      @refresh_token = @_refresh.token
      link_access_to_refresh
    end

    def create_access_token
      @_access = AccessToken.create(
        @_csrf.encoded,
        payload,
        store,
        JWTSessions.custom_access_expiration(@_access_exp)
      )
      @access_token = @_access.token
    end
  end
end
