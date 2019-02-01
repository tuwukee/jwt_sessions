# frozen_string_literal: true

require "minitest/autorun"
require "jwt_sessions"

class TestRedisStoreAdapter < Minitest::Test
  def teardown
    JWTSessions.remove_instance_variable(:@redis_host) if JWTSessions.instance_variable_defined?(:@redis_host)
    JWTSessions.remove_instance_variable(:@redis_port) if JWTSessions.instance_variable_defined?(:@redis_port)
    JWTSessions.remove_instance_variable(:@redis_db_name) if JWTSessions.instance_variable_defined?(:@redis_db_name)
    JWTSessions.remove_instance_variable(:@redis_url) if JWTSessions.instance_variable_defined?(:@redis_url)
  end

  def test_error_on_mixed_redis_options
    assert_raises ArgumentError do
      JWTSessions::StoreAdapters::RedisStoreAdapter.new(
        redis_url: "redis://127.0.0.1:6379/0",
        redis_port: "8082"
      )
    end
  end

  def test_error_on_unknown_option
    assert_raises ArgumentError do
      JWTSessions::StoreAdapters::RedisStoreAdapter.new(
        redis_url: "redis://127.0.0.1:6379/0",
        something: "something"
      )
    end
  end

  def test_default_url
    adapter = JWTSessions::StoreAdapters::RedisStoreAdapter.new
    assert_equal "redis://127.0.0.1:6379/0", adapter.storage.connection[:id]
  end

  def test_url_with_env_var
    ENV["REDIS_URL"] = "redis://locallol:2018/"
    adapter = JWTSessions::StoreAdapters::RedisStoreAdapter.new
    assert_equal "redis://locallol:2018/0", adapter.storage.connection[:id]

    ENV.delete("REDIS_URL")
    adapter = JWTSessions::StoreAdapters::RedisStoreAdapter.new
    assert_equal "redis://127.0.0.1:6379/0", adapter.storage.connection[:id]
  end

  def test_configuration_via_host_port_and_db
    adapter = JWTSessions::StoreAdapters::RedisStoreAdapter.new(
      redis_host: "127.0.0.2",
      redis_port: "6372",
      redis_db_name: "2"
    )
    assert_equal "redis://127.0.0.2:6372/2", adapter.storage.connection[:id]
  end

  def test_configuration_via_host_port_and_db_in_module
    JWTSessions.redis_host = "127.0.0.2"
    JWTSessions.redis_port = "6372"
    JWTSessions.redis_db_name = "2"

    adapter = JWTSessions::StoreAdapters::RedisStoreAdapter.new
    assert_equal "redis://127.0.0.2:6372/2", adapter.storage.connection[:id]
  end

  def test_configuration_via_redis_url
    adapter = JWTSessions::StoreAdapters::RedisStoreAdapter.new(redis_url: "redis://127.0.0.2:6322")
    assert_equal "redis://127.0.0.2:6322/0", adapter.storage.connection[:id]
  end

  def test_configuration_via_redis_url_in_module
    JWTSessions.redis_url = "redis://127.0.0.2:6322"
    adapter = JWTSessions::StoreAdapters::RedisStoreAdapter.new
    assert_equal "redis://127.0.0.2:6322/0", adapter.storage.connection[:id]
  end
end
