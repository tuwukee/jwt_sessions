# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestToken < Minitest::Test
  attr_accessor :payload

  def setup
    JWTSessions.encryption_key = '65994c7b523a3232e7aba54d8cbf'
    @payload = { 'user_id' => 1 }
  end

  def test_valid_token_decode
    token = JWTSessions::Token.encode(payload)
    assert_equal payload['user_id'], JWTSessions::Token.decode(token).first['user_id']
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
