# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../../../../lib', __FILE__)
require 'jwt'
require 'jwt_sessions'
require 'sinatra'
require 'sinatra/namespace'

JWTSessions.encryption_key = 'secret key'
JWTSessions.token_store = ENV['STORE_ADAPTER'] || 'redis'

get '/' do
  'Welcome to Sinatra app!'
end

namespace '/api/v1' do
  include JWTSessions::Authorization

  # rack headers standard
  ACCESS_HEADER  = "HTTP_#{JWTSessions.access_header.downcase.gsub(/-/,'_').upcase}"
  REFRESH_HEADER = "HTTP_#{JWTSessions.refresh_header.downcase.gsub(/-/,'_').upcase}"
  CSRF_HEADER    = "HTTP_#{JWTSessions.csrf_header.downcase.gsub(/-/,'_').upcase}"

  before do
    content_type 'application/json'
  end

  def request_headers
    jwt_headers = {}
    jwt_headers[JWTSessions.access_header]  = request.env[ACCESS_HEADER] if request.env[ACCESS_HEADER]
    jwt_headers[JWTSessions.refresh_header] = request.env[REFRESH_HEADER] if request.env[REFRESH_HEADER]
    jwt_headers[JWTSessions.csrf_header]    = request.env[CSRF_HEADER] if request.env[CSRF_HEADER]
    jwt_headers
  end

  def request_cookies
    request.cookies
  end

  def request_method
    request.request_method
  end

  error JWTSessions::Errors::Unauthorized do
    { error: 'Unauthorized' }.to_json
  end

  post '/login' do
    access_payload = { key: 'big access value' }
    refresh_payload = { refresh_key: 'small refresh value' }
    session = JWTSessions::Session.new(
      payload: access_payload,
      refresh_payload: refresh_payload,
      refresh_by_access_allowed: true
    )
    session.login.to_json
  end

  post '/refresh' do
    authorize_refresh_request!
    access_payload = payload.merge({ key: 'reloaded access value' })
    session = JWTSessions::Session.new(payload: access_payload, refresh_payload: payload)
    session.refresh(found_token).to_json
  end

  post '/refresh_by_cookies' do
    authorize_by_refresh_cookie!
    access_payload = payload.merge({ key: 'new access value' })
    session = JWTSessions::Session.new(payload: access_payload, refresh_payload: payload)
    session.refresh(found_token).to_json
  end

  post '/refresh_by_headers' do
    authorize_by_refresh_header!
    access_payload = payload.merge({ key: 'a little shy access value' })
    session = JWTSessions::Session.new(payload: access_payload, refresh_payload: payload)
    session.refresh(found_token).to_json
  end

  post '/refresh_by_access' do
    authorize_refresh_by_access_request!
    access_payload = payload.merge({ key: 'a big brave access value' })
    session = JWTSessions::Session.new(
      payload: access_payload,
      refresh_payload: payload,
      refresh_by_access_allowed: true
    )
    session.refresh_by_access_payload.to_json
  end

  post '/refresh_by_access_by_cookies' do
    authorize_refresh_by_access_cookie!
    access_payload = payload.merge({ key: 'such many auth methods much wow access value' })
    session = JWTSessions::Session.new(
      payload: access_payload,
      refresh_payload: payload,
      refresh_by_access_allowed: true
    )
    session.refresh_by_access_payload.to_json
  end

  post '/refresh_by_access_by_headers' do
    authorize_refresh_by_access_header!
    access_payload = payload.merge({ key: 'yet another access value' })
    session = JWTSessions::Session.new(
      payload: access_payload,
      refresh_payload: payload,
      refresh_by_access_allowed: true
    )
    session.refresh_by_access_payload.to_json
  end

  get '/payload' do
    authorize_access_request!
    payload.to_json
  end

  get '/payload_by_cookies' do
    authorize_access_request_by_cookies!
    payload.to_json
  end

  get '/payload_by_headers' do
    authorize_access_request_by_headers!
    payload.to_json
  end
end
