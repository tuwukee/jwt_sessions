# frozen_string_literal: true
module JWTSessions
  module Strategies
    class CookieBasedStrategy
      def self.resolve(request, token_type = :access)
        cookies = request.cookie_jar
        token_key = "#{JwtSessions.tokens_prefix}#{token_type}_token"
        token = cookies[token_key]
        raise Errors::Unauthorized, "#{token_type} token not found" unless token
        token
      end
    end
  end
end

