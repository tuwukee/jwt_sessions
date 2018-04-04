# frozen_string_literal: true

module JWTSessions
  module Authorization
    CSRF_SAFE_METHODS = %w[GET HEAD].freeze
    TOKEN_TYPES = %w[access refresh].freeze

    protected

    TOKEN_TYPES.each do |token_type|
      define_method("authenticate_#{token_type}_request!") do
        begin
          cookieless_auth(token_type)
        rescue Errors::Unauthorized
          cookie_based_auth(token_type)
        end

        invalid_authentication unless Token.valid_payload?(payload)
        check_csrf
      end
    end

    private

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

    def cookieless_auth(token_type)
      @_csrf_check = false
      @_raw_token = token_from_headers(JWTSessions.cookie_by(token_type))
    end

    def cookie_based_auth(token_type)
      @_csrf_check = true
      @_raw_token = token_from_cookies(JWTSession.header_by(token_type))
    end

    def retrieve_csrf
      token = requset_headers[csrf_header]
      raise Errors::Unauthorized, 'CSRF token is not found' unless token
      token
    end

    def token_from_headers(token_type)
      raw_token = request_headers[token_header]
      token = raw_token.split(' ')[-1]
      raise Errors::Unauthorized, 'Token is not found among request headers' unless token
      token
    end

    def token_from_cookies(token_type)
      token = request_cookies[token_cookie]
      raise Errors::Unauthorized, 'Token is not found among cookies' unless token
      token
    end

    def payload
      @_payload ||= Token.decode(@token).first
    end
  end
end
