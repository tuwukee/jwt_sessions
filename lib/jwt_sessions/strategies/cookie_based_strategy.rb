# frozen_string_literal: true

module JWTSessions
  module Strategies
    class CookieBasedStrategy
      def self.resolve(request_cookies, token_type = :access)
        token_key = "#{JWTSessions.tokens_prefix}#{token_type}_token"
        token = request_cookies[token_key]
        raise Errors::Unauthorized, "#{token_type} token not found" unless token
        token
      end
    end
  end
end

