# frozen_string_literal: true

require 'jwt_sessions/store_adapters/abstract_store_adapter'
require 'jwt_sessions/store_adapters/redis_store_adapter'
require 'jwt_sessions/store_adapters/memory_store_adapter'

module JWTSessions
  module StoreAdapters
    def self.build_by_name(adapter, options = nil)
      camelized_adapter = adapter.to_s.split('_').map(&:capitalize).join
      adapter_class_name = "#{camelized_adapter}StoreAdapter"
      StoreAdapters.const_get(adapter_class_name).new(options || {})
    end
  end
end
