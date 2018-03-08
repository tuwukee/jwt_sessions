# frozen_string_literal: true

module JWTSessions
  module Authorization
    protected

    def authenticate_request!
      invalid_authentication unless payload && Token.valid_payload(payload)
      check_csrf
    end

    def invalid_authentication
      raise Errors::Unauthorized
    end

    def get_key_from_payload(key)
      payload && payload[key]
    end

    def token_type
      :access
    end

    def tokens_store
      @_tokens_store ||= Redis.new(url: "#{JwtSessions.redis_host}/#{JwtSessions.redis_db_name}")
    end

    def check_csrf(session = nil)
      return if request.get? || request.head?
      session = { _csrf_token: retrieve_csrf } unless session
      if @_csrf_check
        invalid_authentication unless (valid_authenticity_token?(session, form_authenticity_param) ||
          valid_authenticity_token?(session, request.headers['X-CSRF-Token']))
      end
    end

    def retrieve_csrf
      if @token
        tokens_store.get("#{JwtSessions.tokens_prefix}_#{payload['uid']}")
      end
    end

    def cookieless_auth
      @_csrf_check = false
      @token = Strategies::CookielessStrategy.resolve(request, token_type)
    end

    def cookie_based_auth
      @_csrf_check = true
      @token = Strategies::CookieBasedStrategy.resolve(request, token_type)
    end

    private

    def payload
      @payload ||= Token.decode(@token).first if @token
    rescue StandardError
      nil
    end
  end
end
