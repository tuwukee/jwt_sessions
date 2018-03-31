# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestSession < Minitest::Test
  attr_accessor :session, :payload
  EXPECTED_KEYS = [:access, :csrf, :refresh].freeze

  def setup
    JWTSessions.encryption_key = '65994c7b523a3232e7aba54d8cbf'
    @payload = { test: 'test' }
    @session = JWTSessions::Session.new(payload)
  end

  def test_initialization
    token_h = session.login
    decoded_access = JWTSessions::Token.decode(token_h[:access]).first
    assert_equal EXPECTED_KEYS, token_h.keys.sort
    assert_equal payload[:test], decoded_access['test']
  end

  def test_refresh
    token_h = session.login
    refreshed_token_h = session.refresh(token_h[:refresh])
    decoded_access = JWTSessions::Token.decode(refreshed_token_h[:access]).first
    assert_equal EXPECTED_KEYS, refreshed_token_h.keys.sort
    assert_equal payload[:test], decoded_access['test']
  end
end
