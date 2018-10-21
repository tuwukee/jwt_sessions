# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestJWTSessions < Minitest::Test
  def test_default_settings
    assert_equal JWTSessions::DEFAULT_REDIS_HOST, JWTSessions.redis_host
    assert_equal JWTSessions::DEFAULT_REDIS_DB_NAME, JWTSessions.redis_db_name
    assert_equal JWTSessions::DEFAULT_TOKEN_PREFIX, JWTSessions.token_prefix
    assert_equal JWTSessions::DEFAULT_ALGORITHM, JWTSessions.algorithm
    assert_equal JWTSessions::DEFAULT_ACCESS_EXP_TIME, JWTSessions.access_exp_time
    assert_equal JWTSessions::DEFAULT_REFRESH_EXP_TIME, JWTSessions.refresh_exp_time
    assert_equal JWTSessions::DEFAULT_ACCESS_COOKIE, JWTSessions.access_cookie
    assert_equal JWTSessions::DEFAULT_REFRESH_COOKIE, JWTSessions.refresh_cookie
    assert_equal JWTSessions::DEFAULT_ACCESS_HEADER, JWTSessions.access_header
    assert_equal JWTSessions::DEFAULT_REFRESH_HEADER, JWTSessions.refresh_header
    assert_equal JWTSessions::DEFAULT_CSRF_HEADER, JWTSessions.csrf_header
  end

  def test_encryption_key
    JWTSessions.encryption_key = nil
    assert_raises JWTSessions::Errors::Malconfigured do
      JWTSessions.private_key
    end

    assert_raises JWTSessions::Errors::Malconfigured do
      JWTSessions.public_key
    end
  end

  def test_by_token_type
    assert_equal JWTSessions.access_header, JWTSessions.header_by('access')
    assert_equal JWTSessions.refresh_header, JWTSessions.header_by('refresh')
    assert_equal JWTSessions.access_cookie, JWTSessions.cookie_by('access')
    assert_equal JWTSessions.refresh_cookie, JWTSessions.cookie_by('refresh')
  end

  def test_redis_url
    assert_equal 'redis://127.0.0.1:6379/0', JWTSessions.redis_url
  end

  def test_redis_url_with_env_var
    JWTSessions.instance_variable_set(:@redis_url, nil)
    ENV['REDIS_URL'] = 'rediska://locallol:2018/'
    assert_equal 'rediska://locallol:2018/0', JWTSessions.redis_url
    ENV.delete('REDIS_URL')
    JWTSessions.instance_variable_set(:@redis_url, nil)
    assert_equal 'redis://127.0.0.1:6379/0', JWTSessions.redis_url
  end
end
