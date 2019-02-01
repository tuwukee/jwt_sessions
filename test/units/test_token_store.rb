# frozen_string_literal: true

require "minitest/autorun"
require "jwt_sessions"

class TestTokenStore < Minitest::Test
  def teardown
    [:@token_store, :@redis_port].each do |var_name|
      JWTSessions.remove_instance_variable(var_name) if JWTSessions.instance_variable_defined?(var_name)
    end
  end

  def test_setting_redis_token_store_by_default
    assert_instance_of JWTSessions::StoreAdapters::RedisStoreAdapter, JWTSessions.token_store
  end

  def test_setting_redis_token_store_with_default_prefix
    JWTSessions.token_store = :redis, { redis_url: "redis://127.0.0.1:6379/0" }
    assert_instance_of JWTSessions::StoreAdapters::RedisStoreAdapter, JWTSessions.token_store
    assert_equal "jwt_", JWTSessions.token_store.prefix
  end

  def test_setting_redis_token_store
    JWTSessions.token_store = :redis, { redis_url: "redis://127.0.0.1:6379/0", token_prefix: "prefix" }
    assert_instance_of JWTSessions::StoreAdapters::RedisStoreAdapter, JWTSessions.token_store
    assert_equal "prefix", JWTSessions.token_store.prefix
  end

  def test_setting_redis_token_store_along_with_module_configuration
    JWTSessions.redis_port = 6378
    JWTSessions.token_store = :redis

    assert_equal "redis://127.0.0.1:6378/0", JWTSessions.token_store.storage.connection[:id]
  end

  def test_setting_redis_token_store_without_options
    JWTSessions.token_store = :redis
    assert_instance_of JWTSessions::StoreAdapters::RedisStoreAdapter, JWTSessions.token_store
  end

  def test_setting_memory_token_store
    JWTSessions.token_store = :memory
    assert_instance_of JWTSessions::StoreAdapters::MemoryStoreAdapter, JWTSessions.token_store
  end

  def test_setting_unknown_adapter
    assert_raises(NameError) { JWTSessions.token_store = :tape }
  end
end
