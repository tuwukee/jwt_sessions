# frozen_string_literal: true

require "securerandom"
require "uri"

require "jwt_sessions/errors"
require "jwt_sessions/token"
require "jwt_sessions/refresh_token"
require "jwt_sessions/csrf_token"
require "jwt_sessions/access_token"
require "jwt_sessions/session"
require "jwt_sessions/authorization"
require "jwt_sessions/rails_authorization" if defined?(::Rails)
require "jwt_sessions/version"
require "jwt_sessions/store_adapters"

module JWTSessions
  extend self

  attr_accessor :redis_url

  NONE = "none"

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

  DEFAULT_REDIS_HOST       = "127.0.0.1"
  DEFAULT_REDIS_PORT       = "6379"
  DEFAULT_REDIS_DB_NAME    = "0"
  DEFAULT_TOKEN_PREFIX     = "jwt_"
  DEFAULT_ALGORITHM        = "HS256"
  DEFAULT_ACCESS_EXP_TIME  = 3600 # 1 hour in seconds
  DEFAULT_REFRESH_EXP_TIME = 604800 # 1 week in seconds
  DEFAULT_ACCESS_COOKIE    = "jwt_access"
  DEFAULT_ACCESS_HEADER    = "Authorization"
  DEFAULT_REFRESH_COOKIE   = "jwt_refresh"
  DEFAULT_REFRESH_HEADER   = "X-Refresh-Token"
  DEFAULT_CSRF_HEADER      = "X-CSRF-Token"

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

  def token_store=(args)
    adapter, options = Array(args)
    @token_store = StoreAdapters.build_by_name(adapter, options)
  rescue NameError => e
    raise e.class, "Token store adapter for :#{adapter} haven't been found", e.backtrace
  end

  def token_store
    unless instance_variable_defined?(:@token_store)
      begin
        self.token_store = :redis
      rescue LoadError
        warn <<~MSG
          Warning! JWTSessions uses in-memory token store.
          Unless token store is specified explicitly, JWTSessions uses Redis by default and fallbacks to in-memory token store.

          To get rid of this message specify the memory store explicitly in the settings or make sure 'redis' gem is present in your Gemfile.
        MSG

        self.token_store = :memory
      end
    end

    @token_store
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

  def custom_access_expiration(time)
    Time.now.to_i + (time || access_exp_time).to_i
  end

  def custom_refresh_expiration(time)
    Time.now.to_i + (time || refresh_exp_time).to_i
  end

  def header_by(token_type)
    send("#{token_type}_header")
  end

  def cookie_by(token_type)
    send("#{token_type}_cookie")
  end

  private

  def supported_algos
    algos = JWT::Algos.constants - [:Unsupported]
    algos.map { |algo| JWT::Algos.const_get(algo)::SUPPORTED }.flatten + [NONE]
  end
end
