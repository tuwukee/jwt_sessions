# frozen_string_literal: true

require File.expand_path '../spec_helper.rb', __FILE__

describe 'Sinatra Application' do
  LOGIN_KEYS = %w[access access_expires_at csrf refresh refresh_expires_at].freeze
  REFRESH_KEYS = %w[access access_expires_at csrf].freeze

  def json(body)
    JSON.parse(body) rescue {}
  end

  it 'home page' do
    get '/'
    expect(last_response).to be_ok
  end

  it 'should allow to log in' do
    post '/api/v1/login', format: :json
    expect(last_response).to be_ok
    expect(json(last_response.body).keys.sort).to eq LOGIN_KEYS
  end

  it 'should allow to refresh' do
    post '/api/v1/login', format: :json
    expect(last_response).to be_ok
    refresh_token = json(last_response.body)['refresh']
    header JWTSessions.refresh_header.downcase.gsub(/\s+/,'_').upcase, refresh_token
    post '/api/v1/refresh', format: :json
    expect(last_response).to be_ok
    expect(json(last_response.body).keys.sort).to eq REFRESH_KEYS
  end

  it 'should allow to access' do
    post '/api/v1/login', format: :json
    expect(last_response).to be_ok
    access_token = json(last_response.body)['access']
    header JWTSessions.access_header.downcase.gsub(/\s+/,'_').upcase, access_token
    get '/api/v1/payload', format: :json
    expect(last_response).to be_ok
    expect(json(last_response.body)['key']).to eq 'big access value'
  end

  it 'should allow to access with refreshed token' do
    post '/api/v1/login', format: :json
    expect(last_response).to be_ok
    refresh_token = json(last_response.body)['refresh']
    header JWTSessions.refresh_header.downcase.gsub(/\s+/,'_').upcase, refresh_token
    post '/api/v1/refresh', format: :json
    expect(last_response).to be_ok
    access_token = json(last_response.body)['access']
    header JWTSessions.access_header.downcase.gsub(/\s+/,'_').upcase, access_token
    get '/api/v1/payload', format: :json
    expect(last_response).to be_ok
    expect(json(last_response.body)['key']).to eq 'reloaded access value'
  end
end
