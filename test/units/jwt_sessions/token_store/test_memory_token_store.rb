require 'minitest/autorun'
require 'jwt_sessions'
require_relative 'token_store_shared'

class TestMemoryTokenStore < Minitest::Test
  def setup
    @uid = SecureRandom.uuid
    @csrf = JWTSessions::CSRFToken.new.encoded
    @store = JWTSessions::TokenStore::MemoryTokenStore.instance
  end

  def teardown
    JWTSessions::TokenStore::MemoryTokenStore.clear
  end

  include TokenStoreShared
end
