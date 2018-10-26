# frozen_string_literal: true

require 'redis'

module JWTSessions
  module TokenStore
    class AbstractTokenStore
      class << self
        def instance(_options); end

        def clear
          @instance = nil
        end
      end

      def fetch_access(_uid); end

      def persist_access(_uid, _csrf, _expiration); end

      def fetch_refresh(_uid, _namespace); end

      def persist_refresh(_uid, _access_expiration, _access_uid, _csrf, _expiration, _namespace = nil); end

      def update_refresh(_uid, _access_expiration, _access_uid, _csrf, _namespace = nil); end

      def all(_namespace); end

      def destroy_refresh(_uid, _namespace); end

      def destroy_access(_uid); end
    end
  end
end
