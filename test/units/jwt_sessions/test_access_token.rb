# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestAccessToken < Minitest::Test
   attr_reader :access_token, :uid

  def setup
    JWTSessions.encryption_key = 'secret key'
    @payload = { user_id: 1 }
    @csrf = JWTSessions::CSRFToken.new
    @uid = SecureRandom.uuid
    @access_token = JWTSessions::AccessToken.create(@csrf.encoded,
                                                    @payload,
                                                    JWTSessions.token_store)
  end

  def test_csrf
    token = JWTSessions.token_store.fetch_access(access_token.uid)
    assert_equal token[:csrf], access_token.csrf
    access_token.destroy
  end

  def test_destroy
    JWTSessions::AccessToken.destroy(access_token.uid, JWTSessions.token_store)
    token = JWTSessions.token_store.fetch_access(access_token.uid)
    assert_equal({}, token)
  end
end
