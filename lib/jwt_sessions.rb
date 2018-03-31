# frozen_string_literal: true

require 'securerandom'

require 'jwt_sessions/errors'
require 'jwt_sessions/token'
require 'jwt_sessions/redis_token_store'
require 'jwt_sessions/refresh_token'
require 'jwt_sessions/csrf_token'
require 'jwt_sessions/access_token'
require 'jwt_sessions/strategies/cookie_based_strategy'
require 'jwt_sessions/strategies/cookieless_strategy'
require 'jwt_sessions/session'
require 'jwt_sessions/authorization'
require 'jwt_sessions/version'

module JWTSessions
  extend self

  attr_writer :token_store

  DEFAULT_SETTINGS_KEYS = %i[redis_host
                             redis_port
                             redis_db_name
                             token_prefix
                             algorithm
                             exp_time
                             refresh_exp_time].freeze
  DEFAULT_REDIS_HOST = '127.0.0.1'
  DEFAULT_REDIS_PORT = '6379'
  DEFAULT_REDIS_DB_NAME = 'jwtokens'
  DEFAULT_TOKEN_PREFIX = 'jwt_'
  DEFAULT_ALGORITHM = 'HS256'
  DEFAULT_EXP_TIME = 3600 # 1 hour in seconds
  DEFAULT_REFRESH_EXP_TIME = 604800 # 1 week in seconds


  DEFAULT_SETTINGS_KEYS.each do |setting|
    define_method(setting) do
      instance_variable_get(:"@#{setting}") ||
        instance_variable_set(:"@#{setting}",
                              const_get("DEFAULT_#{setting.upcase}"))
    end

    define_method("#{setting}=") do |val|
      instance_variable_set(:"@#{setting}", val)
    end
  end

  def token_store
    @token_store ||= RedisTokenStore.instance(redis_host, redis_port, redis_db_name, token_prefix)
  end

  def encryption_key
    raise Errors::Malconfigured, 'encryption_key is not specified' unless @encryption_key
    @encryption_key
  end

  def access_expiration
    Time.now.to_i + exp_time.to_i
  end

  def refresh_expiration
    Time.now.to_i + refresh_exp_time.to_i
  end

  def encryption_key=(key)
    @encryption_key = key
  end
end
