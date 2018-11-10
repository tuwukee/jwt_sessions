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

  it 'allows to log in' do
    post '/api/v1/login', format: :json
    expect(last_response).to be_ok
    expect(json(last_response.body).keys.sort).to eq LOGIN_KEYS
  end

  context 'allows to refresh by cookies and headers' do
    before { post '/api/v1/login', format: :json }

    it 'refreshes by headers' do
      clear_cookies
      refresh_token = json(last_response.body)['refresh']
      header JWTSessions.refresh_header.downcase.gsub(/\s+/,'_').upcase, refresh_token
      post '/api/v1/refresh', format: :json
      expect(last_response).to be_ok
      expect(json(last_response.body).keys.sort).to eq REFRESH_KEYS
    end

    it 'refreshes by cookies' do
      refresh_token = json(last_response.body)['refresh']
      csrf_token = json(last_response.body)['csrf']
      set_cookie "#{JWTSessions.refresh_cookie}=#{refresh_token}"
      header JWTSessions.csrf_header.downcase.gsub(/\s+/,'_').upcase, csrf_token
      post '/api/v1/refresh', format: :json
      expect(last_response).to be_ok
      expect(json(last_response.body).keys.sort).to eq REFRESH_KEYS
    end
  end

  context 'allows to refresh by cookies only' do
    before { post '/api/v1/login', format: :json }

    it 'refreshes by cookies' do
      refresh_token = json(last_response.body)['refresh']
      csrf_token = json(last_response.body)['csrf']
      set_cookie "#{JWTSessions.refresh_cookie}=#{refresh_token}"
      header JWTSessions.csrf_header.downcase.gsub(/\s+/,'_').upcase, csrf_token
      post '/api/v1/refresh_by_cookies', format: :json
      expect(last_response).to be_ok
      expect(json(last_response.body).keys.sort).to eq REFRESH_KEYS
    end

    it 'refreshes by headers' do
      clear_cookies
      refresh_token = json(last_response.body)['refresh']
      header JWTSessions.refresh_header.downcase.gsub(/\s+/,'_').upcase, refresh_token
      post '/api/v1/refresh_by_cookies', format: :json
      expect(last_response).to_not be_ok
      expect(json(last_response.body)['error']).to eq 'Unauthorized'
    end
  end

  context 'allows to refresh by headers only' do
    before { post '/api/v1/login', format: :json }

    it 'refreshes by cookies' do
      refresh_token = json(last_response.body)['refresh']
      csrf_token = json(last_response.body)['csrf']
      set_cookie "#{JWTSessions.refresh_cookie}=#{refresh_token}"
      header JWTSessions.csrf_header.downcase.gsub(/\s+/,'_').upcase, csrf_token
      post '/api/v1/refresh_by_headers', format: :json
      expect(last_response).to_not be_ok
      expect(json(last_response.body)['error']).to eq 'Unauthorized'
    end

    it 'refreshes by headers' do
      clear_cookies
      refresh_token = json(last_response.body)['refresh']
      header JWTSessions.refresh_header.downcase.gsub(/\s+/,'_').upcase, refresh_token
      post '/api/v1/refresh_by_headers', format: :json
      expect(last_response).to be_ok
      expect(json(last_response.body).keys.sort).to eq REFRESH_KEYS
    end
  end

  context 'allows to refresh by access token by cookies and headers' do
    before { post '/api/v1/login', format: :json }

    it 'refreshes by headers' do
      clear_cookies
      access_token = json(last_response.body)['access']
      header JWTSessions.access_header.downcase.gsub(/\s+/,'_').upcase, access_token
      post '/api/v1/refresh_by_access', format: :json
      expect(last_response).to be_ok
      expect(json(last_response.body).keys.sort).to eq REFRESH_KEYS
    end

    it 'refreshes by cookies' do
      access_token = json(last_response.body)['access']
      csrf_token = json(last_response.body)['csrf']
      set_cookie "#{JWTSessions.access_cookie}=#{access_token}"
      header JWTSessions.csrf_header.downcase.gsub(/\s+/,'_').upcase, csrf_token
      post '/api/v1/refresh_by_access', format: :json
      expect(last_response).to be_ok
      expect(json(last_response.body).keys.sort).to eq REFRESH_KEYS
    end
  end

  context 'allows to refresh by access token by cookies only' do
    before { post '/api/v1/login', format: :json }

    it 'refreshes by cookies' do
      access_token = json(last_response.body)['access']
      csrf_token = json(last_response.body)['csrf']
      set_cookie "#{JWTSessions.access_cookie}=#{access_token}"
      header JWTSessions.csrf_header.downcase.gsub(/\s+/,'_').upcase, csrf_token
      post '/api/v1/refresh_by_access_by_cookies', format: :json
      expect(last_response).to be_ok
      expect(json(last_response.body).keys.sort).to eq REFRESH_KEYS
    end

    it 'refreshes by headers' do
      clear_cookies
      access_token = json(last_response.body)['access']
      header JWTSessions.access_header.downcase.gsub(/\s+/,'_').upcase, access_token
      post '/api/v1/refresh_by_access_by_cookies', format: :json
      expect(last_response).to_not be_ok
      expect(json(last_response.body)['error']).to eq 'Unauthorized'
    end
  end

  context 'allows to refresh by access token by headers only' do
    before { post '/api/v1/login', format: :json }

    it 'refreshes by cookies' do
      access_token = json(last_response.body)['access']
      csrf_token = json(last_response.body)['csrf']
      set_cookie "#{JWTSessions.access_cookie}=#{access_token}"
      header JWTSessions.csrf_header.downcase.gsub(/\s+/,'_').upcase, csrf_token
      post '/api/v1/refresh_by_access_by_headers', format: :json
      expect(last_response).to_not be_ok
      expect(json(last_response.body)['error']).to eq 'Unauthorized'
    end

    it 'refreshes by headers' do
      clear_cookies
      access_token = json(last_response.body)['access']
      header JWTSessions.access_header.downcase.gsub(/\s+/,'_').upcase, access_token
      post '/api/v1/refresh_by_access_by_headers', format: :json
      expect(last_response).to be_ok
      expect(json(last_response.body).keys.sort).to eq REFRESH_KEYS
    end
  end

  it 'allows to access' do
    post '/api/v1/login', format: :json
    expect(last_response).to be_ok
    access_token = json(last_response.body)['access']
    header JWTSessions.access_header.downcase.gsub(/\s+/,'_').upcase, access_token
    get '/api/v1/payload', format: :json
    expect(last_response).to be_ok
    expect(json(last_response.body)['key']).to eq 'big access value'
  end

  it 'allows to access with refreshed token' do
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
