# frozen_string_literal: true

module JWTSessions
  module Authorization
    CSRF_SAFE_METHODS = %w[GET HEAD].freeze
    TOKEN_TYPES = %w[access refresh].freeze

    protected

    TOKEN_TYPES.each do |token_type|
      define_method("authorize_#{token_type}_request!") do
        begin
          cookieless_auth(token_type)
        rescue Errors::Unauthorized
          cookie_based_auth(token_type)
        end
        # triggers token decode and jwt claim checks
        payload
        invalid_authorization unless session_exists?(token_type)
        check_csrf(token_type)
      end
    end

    def authorize_refresh_by_access_request!
      begin
        cookieless_auth(:access)
      rescue Errors::Unauthorized
        cookie_based_auth(:access)
      end

      invalid_authorization if should_check_csrf? && @_csrf_check && !JWTSessions::Session.new.valid_access_request?(retrieve_csrf, claimless_payload)
    end

    private

    def invalid_authorization
      raise Errors::Unauthorized
    end

    def check_csrf(token_type)
      invalid_authorization if should_check_csrf? && @_csrf_check && !valid_csrf_token?(retrieve_csrf, token_type)
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

    def valid_csrf_token?(csrf_token, token_type)
      JWTSessions::Session.new.valid_csrf?(found_token, csrf_token, token_type)
    end

    def session_exists?(token_type)
      JWTSessions::Session.new.session_exists?(found_token, token_type)
    end

    def cookieless_auth(token_type)
      @_csrf_check = false
      @_raw_token = token_from_headers(token_type)
    end

    def cookie_based_auth(token_type)
      @_csrf_check = true
      @_raw_token = token_from_cookies(token_type)
    end

    def retrieve_csrf
      token = request_headers[JWTSessions.csrf_header]
      raise Errors::Unauthorized, 'CSRF token is not found' unless token
      token
    end

    def token_from_headers(token_type)
      raw_token = request_headers[JWTSessions.header_by(token_type)] || ''
      token = raw_token.split(' ')[-1]
      raise Errors::Unauthorized, 'Token is not found' unless token
      token
    end

    def token_from_cookies(token_type)
      token = request_cookies[JWTSessions.cookie_by(token_type)]
      raise Errors::Unauthorized, 'Token is not found' unless token
      token
    end

    def found_token
      @_raw_token
    end

    def payload
      claims = respond_to?(:token_claims) ? token_claims : {}
      @_payload ||= Token.decode(found_token, claims).first
    end

    # retrieves tokens payload without JWT claims validation
    def claimless_payload
      @_claimless_payload ||= Token.decode!(found_token).first
    end
  end
end
