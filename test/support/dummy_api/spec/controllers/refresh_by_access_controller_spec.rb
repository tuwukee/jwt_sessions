# frozen_string_literal: true

describe RefreshByAccessController do
  let(:password) { 'password123' }
  let!(:user) { create(:user) }

  describe 'POST #create' do
    EXPECTED_RBA_KEYS = %w[csrf].freeze

    context 'success' do
      let(:access_token) { "Bearer #{@tokens[:access]}" }
      let(:access_cookie) { @tokens[:access] }
      let(:csrf_token) { @tokens[:csrf] }

      before do
        JWTSessions.access_exp_time = 0
        payload = { user_id: user.id }
        session = JWTSessions::Session.new(payload: payload, refresh_by_access_allowed: true)
        @tokens = session.login
        JWTSessions.access_exp_time = 3600
      end

      it do
        request.headers[JWTSessions.access_header] = access_token
        post :create
        expect(response).to be_successful
        expect(response_json.keys.sort).to eq EXPECTED_RBA_KEYS
      end

      it do
        request.headers[JWTSessions.access_header.downcase] = access_token
        post :create
        expect(response).to be_successful
        expect(response_json.keys.sort).to eq EXPECTED_RBA_KEYS
      end

      it do
        request.cookies[JWTSessions.access_cookie] = access_cookie
        request.headers[JWTSessions.csrf_header] = csrf_token
        post :create
        expect(response).to be_successful
        expect(response_json.keys.sort).to eq EXPECTED_RBA_KEYS
      end
    end

    context 'failure' do
      let(:access_cookie) { @tokens[:access] }
      let(:csrf_token) { @tokens[:csrf] }

      before do
        payload = { user_id: user.id }
        session = JWTSessions::Session.new(payload: payload, refresh_by_access_allowed: true)
        @tokens = session.login
      end

      context 'Refresh before access is expired' do
        let(:access_token) { "Bearer #{@tokens[:access]}" }
        let(:access_cookie) { @tokens[:access] }
        let(:csrf_token) { @tokens[:csrf] }

        it do
          request.headers[JWTSessions.access_header] = access_token
          post :create
          expect(response.code).to eq '401'
        end

        it do
          request.headers[JWTSessions.access_header.downcase] = access_token
          post :create
          expect(response.code).to eq '401'
        end

        it do
          request.cookies[JWTSessions.access_cookie] = access_cookie
          request.headers[JWTSessions.csrf_header] = csrf_token
          post :create
          expect(response.code).to eq '401'
        end
      end

      it 'requires CSRF for cookie based auth' do
        request.cookies[JWTSessions.access_cookie] = access_cookie
        post :create
        expect(response.code).to eq '401'
      end

      it 'tokens are absent' do
        post :create
        expect(response.code).to eq '401'
      end

      it do
        request.cookies[JWTSessions.access_cookie] = 123
        post :create
        expect(response.code).to eq '401'
      end

      it do
        request.cookies[JWTSessions.access_cookie] = 'abc'
        request.headers[JWTSessions.csrf_header] = csrf_token
        post :create
        expect(response.code).to eq '401'
      end

      it do
        request.cookies[JWTSessions.access_header] = '123abc'
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
