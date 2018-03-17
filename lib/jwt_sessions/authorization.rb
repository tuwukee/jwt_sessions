# frozen_string_literal: true

module JWTSessions
  module Authorization
    protected

    def authenticate_request!
      begin
        cookieless_auth
      rescue Errors::Unauthorized
        cookie_based_auth
      end

      invalid_authentication unless Token.valid_payload?(payload)
      check_csrf
    end

    def invalid_authentication
      raise Errors::Unauthorized
    end

    def get_from_payload(key)
      payload[key]
    end

    def token_type
      :access
    end

    def check_csrf
      invalid_authentication if @_csrf_check && !valid_csrf_token?(retrieve_csrf)
    end

    def retrieve_csrf
      TokenStore.get_csrf(payload['uid']) if @token
    end

    def valid_csrf_token?(csrf_token)
      raise Errors::Malconfigured, 'valid_csrf_token? is not implemented'
    end

    def request_headers
      raise Errors::Malconfigured, 'request_headers is not implemented'
    end

    def request_cookies
      raise Errors::Malconfigured, 'request_cookies is not implemented'
    end

    def cookieless_auth
      @_csrf_check = false
      @token = Strategies::CookielessStrategy.resolve(request_headers, token_type)
    end

    def cookie_based_auth
      @_csrf_check = true
      @token = Strategies::CookieBasedStrategy.resolve(request_cookies, token_type)
    end

    private

    def payload
      @payload ||= begin
        payload = Token.decode(@token)&.first
        raise Errors::Unauthorized, 'undefined payload' unless payload
        payload
      end
    end
  end
end
