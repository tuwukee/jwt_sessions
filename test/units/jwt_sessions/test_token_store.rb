# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestTokenStore < Minitest::Test
  def test_redis_adapter
    store = JWTSessions::TokenStore.adapter(:redis,
                                            url: JWTSessions.redis_url,
                                            prefix: '')
    assert_kind_of JWTSessions::TokenStore::RedisTokenStore, store
  end

  def test_memory_adapter
    store = JWTSessions::TokenStore.adapter(:memory)
    assert_kind_of JWTSessions::TokenStore::MemoryTokenStore, store
  end

  def test_unknown_adapter
    assert_raises JWTSessions::Errors::Malconfigured do
      JWTSessions::TokenStore.adapter(:unknown)
    end
  end
end
