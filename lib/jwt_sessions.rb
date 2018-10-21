# frozen_string_literal: true

require 'securerandom'
require 'uri'

require 'jwt_sessions/errors'
require 'jwt_sessions/token'
require 'jwt_sessions/token_store'
require 'jwt_sessions/storage_adapter'
require 'jwt_sessions/refresh_token'
require 'jwt_sessions/csrf_token'
require 'jwt_sessions/access_token'
require 'jwt_sessions/session'
require 'jwt_sessions/authorization'
require 'jwt_sessions/rails_authorization' if defined?(::Rails)
require 'jwt_sessions/version'

module JWTSessions
  extend self

  attr_writer :token_store

  NONE = 'none'

  JWTOptions = Struct.new(*JWT::DefaultOptions::DEFAULT_OPTIONS.keys)

  DEFAULT_SETTINGS_KEYS = %i[access_cookie
                             access_exp_time
                             access_header
                             csrf_header
                             redis_db_name
                             redis_host
                             redis_port
                             refresh_cookie
                             refresh_exp_time
                             refresh_header
                             token_prefix].freeze

  DEFAULT_REDIS_HOST       = '127.0.0.1'
  DEFAULT_REDIS_PORT       = '6379'
  DEFAULT_REDIS_DB_NAME    = '0'
  DEFAULT_TOKEN_PREFIX     = 'jwt_'
  DEFAULT_ALGORITHM        = 'HS256'
  DEFAULT_ACCESS_EXP_TIME  = 3600 # 1 hour in seconds
  DEFAULT_REFRESH_EXP_TIME = 604800 # 1 week in seconds
  DEFAULT_ACCESS_COOKIE    = 'jwt_access'
  DEFAULT_ACCESS_HEADER    = 'Authorization'
  DEFAULT_REFRESH_COOKIE   = 'jwt_refresh'
  DEFAULT_REFRESH_HEADER   = 'X-Refresh-Token'
  DEFAULT_CSRF_HEADER      = 'X-CSRF-Token'

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

  def redis_url
    @redis_url ||= begin
      redis_base_url = ENV['REDIS_URL'] || "redis://#{redis_host}:#{redis_port}"
      URI.join(redis_base_url, redis_db_name).to_s
    end
  end

  def redis_url=(url)
    @redis_url = URI.join(url, redis_db_name).to_s
  end

  def jwt_options
    @jwt_options ||= JWTOptions.new(*JWT::DefaultOptions::DEFAULT_OPTIONS.values)
  end

  def algorithm=(algo)
    raise Errors::Malconfigured, "algorithm #{algo} is not supported" unless supported_algos.include?(algo)
    @algorithm = algo
  end

  def algorithm
    @algorithm ||= DEFAULT_ALGORITHM
  end

  def token_store
    # TokenStore.instance(storage: :Memory, prefix: token_prefix)
    TokenStore.instance(storage: :Redis, prefix: token_prefix)
    # TokenStore.instance(storage: :LRUHash, prefix: token_prefix)
  end

  def validate?
    algorithm != NONE
  end

  [:public_key, :private_key].each do |key|
    var_name = :"@#{key}"
    define_method("#{key}") do
      return nil if algorithm == NONE
      var = instance_variable_get(var_name)
      raise Errors::Malconfigured, "#{key} is not specified" unless var
      var
    end

    define_method("#{key}=") do |val|
      instance_variable_set(var_name, val)
    end
  end

  # should be used for hmac only
  def encryption_key=(key)
    @public_key  = key
    @private_key = key
  end

  def access_expiration
    Time.now.to_i + access_exp_time.to_i
  end

  def refresh_expiration
    Time.now.to_i + refresh_exp_time.to_i
  end

  def header_by(token_type)
    send("#{token_type}_header")
  end

  def cookie_by(token_type)
    send("#{token_type}_cookie")
  end

  private

  def supported_algos
    # TODO once ECDSA is fixed in ruby-jwt it can be added to the list of algos just the same way others are added
    algos = JWT::Algos.constants - [:Unsupported, :Ecdsa]
    algos.map { |algo| JWT::Algos.const_get(algo)::SUPPORTED }.flatten + [NONE, *JWT::Algos::Ecdsa::SUPPORTED.split(' ')]
  end
end
