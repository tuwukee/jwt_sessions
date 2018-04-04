# frozen_string_literal: true

require 'securerandom'

require 'jwt_sessions/errors'
require 'jwt_sessions/token'
require 'jwt_sessions/redis_token_store'
require 'jwt_sessions/refresh_token'
require 'jwt_sessions/csrf_token'
require 'jwt_sessions/access_token'
require 'jwt_sessions/session'
require 'jwt_sessions/authorization'
require 'jwt_sessions/rails_authorization'
require 'jwt_sessions/version'

module JWTSessions
  extend self

  attr_writer :token_store

  DEFAULT_SETTINGS_KEYS = %i[access_cookie
                             access_exp_time
                             access_header
                             algorithm
                             csrf_header
                             redis_db_name
                             redis_host
                             redis_port
                             refresh_cookie
                             refresh_exp_time
                             refresh_header
                             token_prefix].freeze
  DEFAULT_REDIS_HOST = '127.0.0.1'
  DEFAULT_REDIS_PORT = '6379'
  DEFAULT_REDIS_DB_NAME = 'jwtokens'
  DEFAULT_TOKEN_PREFIX = 'jwt_'
  DEFAULT_ALGORITHM = 'HS256'
  DEFAULT_ACCESS_EXP_TIME = 3600 # 1 hour in seconds
  DEFAULT_REFRESH_EXP_TIME = 604800 # 1 week in seconds
  DEFAULT_ACCESS_COOKIE = 'jwt_access'
  DEFAULT_ACCESS_HEADER = 'Authorization'
  DEFAULT_REFRESH_COOKIE= 'jwt_refresh'
  DEFAULT_REFRESH_HEADER = 'X-Refresh-Token'
  DEFAULT_CSRF_HEADER = 'X-CSRF-Token'


  DEFAULT_SETTINGS_KEYS.each do |setting|
    var_name = :"@#{setting}"

    define_method(setting) do
      if instance_variables.include?(var_name)
        instance_variable_get(var_name)
      else
        instance_variable_set(var_name,
                              const_get("DEFAULT_#{setting.upcase}"))
      end
    end

    define_method("#{setting}=") do |val|
      instance_variable_set(var_name, val)
    end
  end

  def token_store
    RedisTokenStore.instance(redis_host, redis_port, redis_db_name, token_prefix)
  end

  def encryption_key
    raise Errors::Malconfigured, 'encryption_key is not specified' unless @encryption_key
    @encryption_key
  end

  def access_expiration
    Time.now.to_i + access_exp_time.to_i
  end

  def refresh_expiration
    Time.now.to_i + refresh_exp_time.to_i
  end

  def encryption_key=(key)
    @encryption_key = key
  end

  def header_by(token_type)
    send("#{token_type}_header")
  end

  def cookie_by(token_type)
    send("#{token_type}_cookie")
  end
end
