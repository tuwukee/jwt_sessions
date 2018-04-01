# frozen_string_literal: true

module JWTSessions
  module Authorization
    CSRF_SAFE_METHODS = ['GET', 'HEAD'].freeze

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

    def check_csrf
      invalid_authentication if should_check_csrf? && @_csrf_check && !valid_csrf_token?(retrieve_csrf)
    end

    def should_check_csrf?
      !CSRF_SAFE_METHODS.include?(request_method)
    end

    def token_header
      raise Errors::Malconfigured, 'token_header is not implemented'
    end

    def token_cookie
      raise Errors::Malconfigured, 'token_cookie is not implemented'
    end

    def csrf_header
      raise Errors::Malconfigured, 'csrf_header is not implemented'
    end

    def request_headers
      raise Errors::Malconfigured, 'request_headers is not implemented'
    end

    def request_cookies
      raise Errors::Malconfigured, 'request_cookies is not implemented'
    end

    def request_method
      raise Errors::Malconfigured, 'request_method is not implemented'
    end

    def valid_csrf_token?(csrf_token)
      JWTSessions::Session.new.valid_csrf?(@_raw_token, csrf_token)
    end

    def cookieless_auth
      @_csrf_check = false
      @_raw_token = token_from_headers
    end

    def cookie_based_auth
      @_csrf_check = true
      @_raw_token = token_from_cookies
    end

    private

    def retrieve_csrf
      token = requset_headers[csrf_header]
      raise Errors::Unauthorized, 'CSRF token is not found' unless token
      token
    end

    def token_from_headers
      raw_token = request_headers[token_header]
      token = raw_token.split(' ')[-1]
      raise Errors::Unauthorized, 'Token is not found among request headers' unless token
      token
    end

    def token_from_cookies
      token = request_cookies[token_cookie]
      raise Errors::Unauthorized, 'Token is not found among cookies' unless token
      token
    end

    def payload
      @_payload ||= Token.decode(@token).first
    end
  end
end
