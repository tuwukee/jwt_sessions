# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestRefreshToken < Minitest::Test
   attr_reader :csrf, :token, :access_uid

  def setup
    JWTSessions.encryption_key = 'secure encryption'
    @access_uid = SecureRandom.uuid
    @csrf = JWTSessions::CSRFToken.new
    @token = JWTSessions::RefreshToken.create(@csrf.encoded,
                                             @access_uid,
                                             JWTSessions.access_expiration - 5,
                                             JWTSessions.token_store,
                                             {},
                                             nil)
  end

  def test_update
    new_access_uid = SecureRandom.uuid
    old_access_expiration = token.access_expiration
    token.update(new_access_uid, JWTSessions.access_expiration, csrf.encoded)
    assert_equal new_access_uid, token.access_uid
    assert_equal true, old_access_expiration != token.access_expiration
    token.destroy
  end

  def test_find
    found_token = JWTSessions::RefreshToken.find(token.uid, JWTSessions.token_store, nil)
    assert_equal found_token.access_uid, token.access_uid
    token.destroy
  end

  def test_destroy
    JWTSessions::RefreshToken.destroy(token.uid, JWTSessions.token_store, nil)
    assert_raises JWTSessions::Errors::Unauthorized do
      JWTSessions::RefreshToken.find(token.uid, JWTSessions.token_store, nil)
    end
  end
end
