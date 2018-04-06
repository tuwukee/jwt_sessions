# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'

class TestCSRFToken < Minitest::Test
   attr_reader :csrf_token

  def setup
    JWTSessions.encryption_key = '65994c7b523a3232e7aba54d8cbf'
    @csrf_token = JWTSessions::CSRFToken.new
  end

  def test_valid_authenticity_token
    assert_equal true, @csrf_token.valid_authenticity_token?(@csrf_token.encoded)
    assert_equal false, @csrf_token.valid_authenticity_token?(nil)
    assert_equal false, @csrf_token.valid_authenticity_token?(123)
    assert_equal false, @csrf_token.valid_authenticity_token?('123abc')
  end
end
