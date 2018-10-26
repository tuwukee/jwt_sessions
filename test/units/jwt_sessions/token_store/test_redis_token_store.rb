require 'minitest/autorun'
require 'jwt_sessions'
require_relative 'token_store_shared'

class TestRedisTokenStore < Minitest::Test
  def setup
    @prefix ||= 'test:jwt'
    @uid = SecureRandom.uuid
    @csrf = JWTSessions::CSRFToken.new.encoded
    @store = JWTSessions::TokenStore::RedisTokenStore.instance(url: JWTSessions.redis_url,
                                                               prefix: @prefix)
  end

  def teardown
    redis = @store.store
    redis.keys("#{@prefix}*").each { |key| redis.del(key) }
  end

  include TokenStoreShared
end
