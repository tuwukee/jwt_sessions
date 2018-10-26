require 'jwt_sessions/token_store/redis_token_store'
require 'jwt_sessions/token_store/memory_token_store'

module JWTSessions
  module TokenStore
    ADAPTERS = {
      redis: RedisTokenStore,
      memory: MemoryTokenStore
    }.freeze

    # @param [Symbol] name adapter name
    # @param [Hash] options options for chosen adapter
    def self.adapter(name, options = {})
      adapter = ADAPTERS.fetch(name.to_sym) do
        raise Errors::Malconfigured, "adapter #{name} is not supported"
      end

      adapter.instance(options)
    end
  end
end
