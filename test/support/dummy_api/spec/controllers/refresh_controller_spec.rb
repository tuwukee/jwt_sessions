# frozen_string_literal: true

describe RefreshController do
  let(:password) { 'password123' }
  let!(:user) { create(:user) }

  describe 'POST #create' do
    before do
      payload = { user_id: user.id }
      session = JWTSessions::Session.new(payload: payload, refresh_payload: payload)
      @tokens = session.login
    end

    EXPECTED_KEYS = %w[access access_expires_at csrf].freeze

    context 'success' do
      let(:refresh_token) { "Bearer #{@tokens[:refresh]}" }
      let(:refresh_cookie) { @tokens[:refresh] }
      let(:csrf_token) { @tokens[:csrf] }

      it do
        request.headers[JWTSessions.refresh_header] = refresh_token
        post :create
        expect(response).to be_successful
        expect(response_json.keys.sort).to eq EXPECTED_KEYS
      end

      it do
        request.headers[JWTSessions.refresh_header.downcase] = refresh_token
        post :create
        expect(response).to be_successful
        expect(response_json.keys.sort).to eq EXPECTED_KEYS
      end

      it do
        request.cookies[JWTSessions.refresh_cookie] = refresh_cookie
        request.headers[JWTSessions.csrf_header] = csrf_token
        post :create
        expect(response).to be_successful
        expect(response_json.keys.sort).to eq EXPECTED_KEYS
      end
    end

    context 'failure' do
      let(:refresh_cookie) { @tokens[:refresh] }
      let(:csrf_token) { @tokens[:csrf] }


      it 'requires CSRF for cookie based auth' do
        request.cookies[JWTSessions.refresh_cookie] = refresh_cookie
        post :create
        expect(response.code).to eq '401'
      end

      it 'tokens are absent' do
        post :create
        expect(response.code).to eq '401'
      end

      it do
        request.cookies[JWTSessions.refresh_cookie] = 123
        post :create
        expect(response.code).to eq '401'
      end

      it do
        request.cookies[JWTSessions.refresh_cookie] = 'abc'
        request.headers[JWTSessions.csrf_header] = csrf_token
        post :create
        expect(response.code).to eq '401'
      end

      it do
        request.cookies[JWTSessions.refresh_header] = '123abc'
        post :create
        expect(response.code).to eq '401'
      end

      it do
        request.headers[JWTSessions.csrf_header] = csrf_token
        post :create
        expect(response.code).to eq '401'
      end
    end
  end
end
