# frozen_string_literal: true
module JWTSessions
  module Strategies
    class CookielessStrategy
      TOKEN_TYPE_HEADERS = {
        access: 'Authorization',
        refresh: 'X-Refresh-Token'
      }.freeze

      def self.resolve(request, token_type = :access)
        header = TOKEN_TYPE_HEADERS[token_type]
        token = nil
        if header
          auth_header = request.headers[header]
          token = auth_header.split(' ').last if auth_header
        end
        raise Errors::Unauthorized, "#{token_type} token not found" unless token
        token
      end
    end
  end
end
