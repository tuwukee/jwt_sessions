# frozen_string_literal: true

require "minitest/autorun"
require "jwt_sessions"

class TestAuthorization < Minitest::Test
  include JWTSessions::Authorization

  def token_claims
    {
      iss: "issuer",
      aud: "audience",
    }
  end

  def setup
    JWTSessions.signing_key = "abcdefghijklmnopqrstuvwxyzABCDEF"
  end

  def teardown
    JWTSessions.jwt_options[:verify_iss] = false
    JWTSessions.jwt_options[:verify_aud] = false
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

  def test_verify_iss
    JWTSessions.jwt_options[:verify_iss] = true

    session = JWTSessions::Session.new(payload: { user_id: 1, iss: "issuer" })
    tokens = session.login

    # Extract uid from access token
    uid = JWT.decode(tokens[:access], JWTSessions.public_key).first["uid"]

    @_raw_token =
      JWTSessions::Token.encode({ user_id: 1, uid: uid, iss: "issuer" })

    assert session_exists?(:access)
  end

  def test_verify_iss_when_iss_is_not_correct
    JWTSessions.jwt_options[:verify_iss] = true

    session = JWTSessions::Session.new(payload: { user_id: 1, iss: "issuer" })
    tokens = session.login

    # Extract uid from access token
    uid = JWT.decode(tokens[:access], JWTSessions.public_key).first["uid"]

    @_raw_token =
      JWTSessions::Token.encode({ user_id: 1, uid: uid, iss: "another_issuer" })

    assert !session_exists?(:access)
  end

  def test_verify_iss_when_iss_is_not_present
    JWTSessions.jwt_options[:verify_iss] = true

    session = JWTSessions::Session.new(payload: { user_id: 1, iss: "issuer" })
    tokens = session.login

    # Extract uid from access token
    uid = JWT.decode(tokens[:access], JWTSessions.public_key).first["uid"]

    @_raw_token =
      JWTSessions::Token.encode({ user_id: 1, uid: uid })

    assert !session_exists?(:access)
  end

  def test_verify_aud
    JWTSessions.jwt_options[:verify_aud] = true

    session = JWTSessions::Session.new(payload: { user_id: 1, aud: "audience" })
    tokens = session.login

    # Extract uid from access token
    uid = JWT.decode(tokens[:access], JWTSessions.public_key).first["uid"]

    @_raw_token =
      JWTSessions::Token.encode({ user_id: 1, uid: uid, aud: "audience" })

    assert session_exists?(:access)
  end

  def test_verify_aud_when_aud_is_not_correct
    JWTSessions.jwt_options[:verify_aud] = true

    session = JWTSessions::Session.new(payload: { user_id: 1, aud: "audience" })
    tokens = session.login

    # Extract uid from access token
    uid = JWT.decode(tokens[:access], JWTSessions.public_key).first["uid"]

    @_raw_token =
      JWTSessions::Token.encode({ user_id: 1, uid: uid, aud: "another_audience" })

    assert !session_exists?(:access)
  end

  def test_verify_aud_when_aud_is_not_present
    JWTSessions.jwt_options[:verify_aud] = true

    session = JWTSessions::Session.new(payload: { user_id: 1, aud: "audience" })
    tokens = session.login

    # Extract uid from access token
    uid = JWT.decode(tokens[:access], JWTSessions.public_key).first["uid"]

    @_raw_token =
      JWTSessions::Token.encode({ user_id: 1, uid: uid })

    assert !session_exists?(:access)
  end
end
