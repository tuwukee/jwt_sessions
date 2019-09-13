# frozen_string_literal: true

module JWTSessions
  module StoreAdapters
    class AbstractStoreAdapter
      def fetch_access(_uid)
        raise NotImplementedError
      end

      def persist_access(_uid, _csrf, _expiration)
        raise NotImplementedError
      end

      # Set first_match to true to look up through all namespaces
      def fetch_refresh(_uid, _namespace, _first_match)
        raise NotImplementedError
      end

      def persist_refresh(_uid:, _access_expiration:, _access_uid:, _csrf:, _expiration:, _namespace:)
        raise NotImplementedError
      end

      def update_refresh(_uid:, _access_expiration:, _access_uid:, _csrf:, _namespace:)
        raise NotImplementedError
      end

      def all_refresh_tokens(_namespace)
        raise NotImplementedError
      end

      def destroy_refresh(_uid, _namespace)
        raise NotImplementedError
      end

      def destroy_access(_uid)
        raise NotImplementedError
      end
    end
  end
end
