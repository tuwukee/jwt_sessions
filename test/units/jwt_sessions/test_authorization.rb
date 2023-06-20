# frozen_string_literal: true

require "minitest/autorun"
require "jwt_sessions"

class TestAuthorization < Minitest::Test
  include JWTSessions::Authorization

  def setup
    JWTSessions.signing_key = "abcdefghijklmnopqrstuvwxyzABCDEF"
  end

  def test_payload_when_token_is_nil
    @_raw_token = nil

    assert_equal payload, {}
  end

  def test_payload_when_token_is_present
    @_raw_token =
      JWTSessions::Token.encode({ "user_id" => 1, "secret" => "mystery" })

    assert_equal payload['user_id'], 1
    assert_equal payload['secret'], 'mystery'
  end
end
