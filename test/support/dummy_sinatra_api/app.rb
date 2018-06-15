$LOAD_PATH.push File.expand_path('../../../../lib', __FILE__)
require 'jwt'
require 'jwt_sessions'
require 'sinatra'
require 'sinatra/namespace'
require 'pry'

JWTSessions.encryption_key = 'secret key'

get '/' do
  'Welcome to Sinatra app!'
end

namespace '/api/v1' do
  include JWTSessions::Authorization

  # rack headers standard
  ACCESS_HEADER = "HTTP_#{JWTSessions.access_header.downcase.gsub(/-/,'_').upcase}"
  REFRESH_HEADER = "HTTP_#{JWTSessions.refresh_header.downcase.gsub(/-/,'_').upcase}"

  before do
    content_type 'application/json'
  end

  def request_headers
    jwt_headers = {}
    jwt_headers[JWTSessions.access_header] = request.env[ACCESS_HEADER] if request.env[ACCESS_HEADER]
    jwt_headers[JWTSessions.refresh_header] = request.env[REFRESH_HEADER] if request.env[REFRESH_HEADER]
    jwt_headers
  end

  def request_cookies
    request.cookies
  end

  def request_method
    request.request_method
  end

  post '/login' do
    access_payload = { key: 'big access value' }
    refresh_payload = { refresh_key: 'small refresh value' }
    session = JWTSessions::Session.new(payload: access_payload, refresh_payload: refresh_payload)
    session.login.to_json
  end

  post '/refresh' do
    authorize_refresh_request!
    access_payload = payload.merge({ key: 'reloaded access value' })
    session = JWTSessions::Session.new(payload: access_payload, refresh_payload: payload)
    session.refresh(found_token).to_json
  end

  get '/payload' do
    authorize_access_request!
    payload.to_json
  end
end

