# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestJWTSessions < Minitest::Test
  def test_default_settings
    assert_equal JWTSessions::DEFAULT_REDIS_HOST, JWTSessions.redis_host
    assert_equal JWTSessions::DEFAULT_REDIS_DB_NAME, JWTSessions.redis_db_name
    assert_equal JWTSessions::DEFAULT_TOKEN_PREFIX, JWTSessions.token_prefix
    assert_equal JWTSessions::DEFAULT_ALGORITHM, JWTSessions.algorithm
    assert_equal JWTSessions::DEFAULT_EXP_TIME, JWTSessions.exp_time
    assert_equal JWTSessions::DEFAULT_REFRESH_EXP_TIME, JWTSessions.refresh_exp_time
  end

  def test_encryption_key
    JWTSessions.encryption_key = nil
    assert_raises JWTSessions::Errors::Malconfigured do
      JWTSessions.encryption_key
    end
  end
end
