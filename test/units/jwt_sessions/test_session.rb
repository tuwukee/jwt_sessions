# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestSession < Minitest::Test
  def setup
    JWTSessions.encryption_key = '65994c7b523a3232e7aba54d8cbf'
  end

  def test_initialization
    s = JWTSessions::Session.new
    token_h = s.login
    assert_equal [:access, :csrf, :refresh], token_h.keys.sort
  end
end
