# frozen_string_literal: true

require 'minitest/autorun'
require 'jwt_sessions'
require 'pry'

nacl_supported_versions = {
  'ruby'  => ['~> 2.2.6', '~> 2.3.0', '~> 2.4.2'],
  'jruby' => ['~> 9.1.6.0']
}.each_with_object([]) do |(platform, versions), acc|
  acc.concat(versions.map { |version| Gem::Dependency.new(platform, version) })
end

nacl_supported = nacl_supported_versions.any? { |version| version.match?(RUBY_ENGINE, RUBY_VERSION) }

$uses_nacl = !!(defined?(RbNaCl) || require('rbnacl') if nacl_supported)

class TestToken < Minitest::Test
  attr_reader :payload

  def setup
    @payload = { 'user_id' => 1, 'secret' => 'mystery' }
    JWTSessions.encryption_key = 'abcdefghijklmnopqrstuvwxyzABCDEF'
  end

  def teardown
    JWTSessions.algorithm = JWTSessions::DEFAULT_ALGORITHM
    JWTSessions.instance_variable_set(:'@jwt_options', JWTSessions::JWTOptions.new(*JWT::DefaultOptions::DEFAULT_OPTIONS.values))
  end

  def test_rsa_token_decode
    JWTSessions.algorithm   = 'RS256'
    JWTSessions.private_key = OpenSSL::PKey::RSA.generate 2048
    JWTSessions.public_key  = JWTSessions.private_key.public_key

    token   = JWTSessions::Token.encode(payload)
    decoded = JWTSessions::Token.decode(token).first
    assert_equal payload['user_id'], decoded['user_id']
    assert_equal payload['secret'], decoded['secret']
  end

  def test_eddsa_token_decode
    skip unless $uses_nacl
    JWTSessions.algorithm   = 'ED25519'
    JWTSessions.private_key = ::RbNaCl::Signatures::Ed25519::SigningKey.new('abcdefghijklmnopqrstuvwxyzABCDEF')
    JWTSessions.public_key  = JWTSessions.private_key.verify_key

    token   = JWTSessions::Token.encode(payload)
    decoded = JWTSessions::Token.decode(token).first
    assert_equal payload['user_id'], decoded['user_id']
    assert_equal payload['secret'], decoded['secret']
  end

  def test_ecdsa_token_decode
    JWTSessions.algorithm   = 'ES256'
    JWTSessions.private_key = OpenSSL::PKey::EC.new 'prime256v1'
    JWTSessions.private_key.generate_key
    JWTSessions.public_key             = OpenSSL::PKey::EC.new JWTSessions.private_key
    JWTSessions.public_key.private_key = nil

    token   = JWTSessions::Token.encode(payload)
    decoded = JWTSessions::Token.decode(token).first
    assert_equal payload['user_id'], decoded['user_id']
    assert_equal payload['secret'], decoded['secret']
  end

  def test_hmac_token_decode
    JWTSessions.encryption_key = 'abcdefghijklmnopqrstuvwxyzABCDEF'
    token   = JWTSessions::Token.encode(payload)
    decoded = JWTSessions::Token.decode(token).first
    assert_equal payload['user_id'], decoded['user_id']
    assert_equal payload['secret'], decoded['secret']
  end

  def test_token_sub_claim
    JWTSessions.encryption_key = 'abcdefghijklmnopqrstuvwxyzABCDEF'
    JWTSessions.jwt_options.verify_sub = true
    token   = JWTSessions::Token.encode(payload.merge(sub: 'subject'))
    decoded = JWTSessions::Token.decode(token, { sub: 'subject' }).first
    assert_equal payload['user_id'], decoded['user_id']
    assert_equal payload['secret'], decoded['secret']
    assert_raises JWTSessions::Errors::ClaimsVerification do
      JWTSessions::Token.decode(token, { sub: 'different subject' })
    end
  end

  def test_token_iss_claim
    JWTSessions.encryption_key = 'abcdefghijklmnopqrstuvwxyzABCDEF'
    JWTSessions.jwt_options.verify_iss = true
    token   = JWTSessions::Token.encode(payload.merge(iss: 'Me'))
    decoded = JWTSessions::Token.decode(token, { iss: 'Me' }).first
    assert_equal payload['user_id'], decoded['user_id']
    assert_equal payload['secret'], decoded['secret']
    assert_raises JWTSessions::Errors::ClaimsVerification do
      JWTSessions::Token.decode(token, { iss: 'Not Me' })
    end
  end

  def test_token_aud_claim
    JWTSessions.encryption_key = 'abcdefghijklmnopqrstuvwxyzABCDEF'
    JWTSessions.jwt_options.verify_aud = true
    token   = JWTSessions::Token.encode(payload.merge(aud: ['young', 'old']))
    decoded = JWTSessions::Token.decode(token, { aud: ['young'] }).first
    assert_equal payload['user_id'], decoded['user_id']
    assert_equal payload['secret'], decoded['secret']
    assert_raises JWTSessions::Errors::ClaimsVerification do
      JWTSessions::Token.decode(token, { aud: ['adult'] })
    end
  end

  def test_token_leeway_decode
    JWTSessions.encryption_key = 'abcdefghijklmnopqrstuvwxyzABCDEF'
    JWTSessions.jwt_options.leeway = 50
    token   = JWTSessions::Token.encode(payload.merge(exp: Time.now.to_i - 20))
    decoded = JWTSessions::Token.decode(token).first
    assert_equal payload['user_id'], decoded['user_id']
    assert_equal payload['secret'], decoded['secret']
    token   = JWTSessions::Token.encode(payload.merge(exp: Time.now.to_i - 100))
    assert_raises JWTSessions::Errors::Unauthorized do
      JWTSessions::Token.decode(token)
    end
  end

  def test_none_token_decode
    JWTSessions.algorithm = JWTSessions::NONE
    token   = JWTSessions::Token.encode(payload)
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
    token = JWTSessions::Token.encode(payload.merge(exp: Time.now.to_i - (3600 * 24)))
    assert_raises JWTSessions::Errors::Unauthorized do
      JWTSessions::Token.decode(token)
    end
  end
end
