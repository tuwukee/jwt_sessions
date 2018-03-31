# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestSession < Minitest::Test
  attr_accessor :session
  EXPECTED_KEYS = [:access, :csrf, :refresh].freeze

  def setup
    JWTSessions.encryption_key = '65994c7b523a3232e7aba54d8cbf'
    @session = JWTSessions::Session.new
  end

  def test_initialization
    token_h = session.login
    assert_equal EXPECTED_KEYS, token_h.keys.sort
  end

  def test_refresh
    token_h = session.login
    result = session.refresh(token_h[:refresh])
    assert_equal EXPECTED_KEYS, result.keys.sort
  end
end
