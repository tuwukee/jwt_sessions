# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestToken < Minitest::Test
  attr_reader :payload

  def setup
    JWTSessions.encryption_key = 'super secret'
    @payload = { 'user_id' => 1, 'secret' => 'mystery' }
  end

  def test_valid_token_decode
    token = JWTSessions::Token.encode(payload)
    decoded = JWTSessions::Token.decode(token).first
    assert_equal payload['user_id'], decoded['user_id']
    assert_equal payload['secret'], decoded['secret']
  end

  def test_invalid_token_decode
    assert_raises JWTSessions::Errors::Unauthorized do
      JWTSessions::Token.decode('abc')
    end
    assert_raises JWTSessions::Errors::Unauthorized do
      JWTSessions::Token.decode('')
    end
    assert_raises JWTSessions::Errors::Unauthorized do
      JWTSessions::Token.decode(nil)
    end
  end

  def test_payload_exp_time
    assert_raises JWTSessions::Errors::Unauthorized do
      JWTSessions::Token.valid_payload?(payload)
    end
    payload['exp'] = Time.now - (3600 * 24)
    assert_equal false, JWTSessions::Token.valid_payload?(payload)
    payload['exp'] = Time.now + (3600 * 24)
    assert_equal true, JWTSessions::Token.valid_payload?(payload)
  end
end
