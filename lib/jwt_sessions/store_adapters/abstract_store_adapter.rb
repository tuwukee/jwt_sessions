# frozen_string_literal: true

module JWTSessions
  module StoreAdapters
    class AbstractStoreAdapter
      def fetch_access(_uuid)
        raise NotImplementedError
      end

      def persist_access(_uuid, _csrf, _expiration)
        raise NotImplementedError
      end

      # Set first_match to true to look up through all namespaces
      def fetch_refresh(_uuid, _namespace, _first_match)
        raise NotImplementedError
      end

      def persist_refresh(_uuid:, _access_expiration:, _access_uuid:, _csrf:, _expiration:, _namespace:)
        raise NotImplementedError
      end

      def update_refresh(_uuid:, _access_expiration:, _access_uuid:, _csrf:, _namespace:)
        raise NotImplementedError
      end

      def all_refresh_tokens(_namespace)
        raise NotImplementedError
      end

      def destroy_refresh(_uuid, _namespace)
        raise NotImplementedError
      end

      def destroy_access(_uuid)
        raise NotImplementedError
      end
    end
  end
end
