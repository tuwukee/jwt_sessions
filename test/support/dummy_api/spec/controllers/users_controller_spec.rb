# frozen_string_literal: true

describe UsersController do
  let(:password) { 'password123' }
  let!(:user) { create(:user) }

  describe 'GET #show' do
    before do
      payload = { user_id: user.id }
      session = JWTSessions::Session.new(payload: payload)
      @tokens = session.login
    end

    context 'success' do
      context 'headers' do
        let(:access_token) { "Bearer #{@tokens[:access]}" }
        before do
          request.headers[JWTSessions.access_header] = access_token
          get :show, params: { id: user.id }
        end

        it do
          expect(response).to be_successful
          expect(response_json).to eq ({ 'current_user' => user.to_json, 'user' => user.to_json })
        end
      end

      context 'cookies' do
        let(:access_cookie) { @tokens[:access] }
        before do
          request.cookies[JWTSessions.access_cookie] = access_cookie
          get :show, params: { id: user.id }
        end

        it do
          expect(response).to be_successful
          expect(response_json).to eq ({ 'current_user' => user.to_json, 'user' => user.to_json })
        end
      end
    end

    context 'failure' do
      context 'no access token' do
        before { get :show, params: { id: user.id } }

        it { expect(response.code).to eq '401' }
      end

      context 'incorrect access token' do
        it do
          request.cookies[JWTSessions.access_cookie] = '123abc'
          get :show, params: { id: user.id }
          expect(response.code).to eq '401'
        end

        it do
          request.headers[JWTSessions.access_header] = 'abc123'
          get :show, params: { id: user.id }
          expect(response.code).to eq '401'
        end
      end

      context 'flushed tokens' do
        let(:access_token) { "Bearer #{@tokens[:access]}" }
        let(:access_cookie) { @tokens[:access] }

        it do
          request.headers[JWTSessions.access_header] = access_token
          session = JWTSessions::Session.new
          session.flush_by_token(@tokens[:refresh])
          get :show, params: { id: user.id }
          expect(response.code).to eq '401'
        end

        it do
          request.cookies[JWTSessions.access_cookie] = access_cookie
          session = JWTSessions::Session.new
          session.flush_by_token(@tokens[:refresh])
          get :show, params: { id: user.id }
          expect(response.code).to eq '401'
        end
      end
    end
  end

  describe 'POST #create' do
    let(:email) { 'new@test.com' }
    let(:user_params) { { user: { email: email, password: password } } }

    before do
      payload = { user_id: user.id }
      session = JWTSessions::Session.new(payload: payload)
      @tokens = session.login
    end

    context 'success' do
      context 'headers' do
        let(:access_token) { "Bearer #{@tokens[:access]}" }
        let(:csrf_token) { @tokens[:csrf] }
        before do
          request.headers[JWTSessions.access_header] = access_token
          request.headers[JWTSessions.csrf_header] = csrf_token
          post :create, params: user_params
        end

        it do
          expect(response).to be_successful
          expect(response_json['current_user']).to eq user.to_json
          expect(JSON.parse(response_json['user'])['email']).to eq email
        end
      end

      context 'cookies' do
        let(:access_cookie) { @tokens[:access] }
        let(:csrf_token) { @tokens[:csrf] }
        before do
          request.cookies[JWTSessions.access_cookie] = access_cookie
          request.headers[JWTSessions.csrf_header] = csrf_token
          post :create, params: user_params
        end

        it do
          expect(response).to be_successful
          expect(response_json['current_user']).to eq user.to_json
          expect(JSON.parse(response_json['user'])['email']).to eq email
        end
      end
    end

    context 'failure' do
      context 'no access token' do
        before { post :create, params: user_params }

        it { expect(response.code).to eq '401' }
      end

      context 'no csrf token' do
        let(:access_token) { "Bearer #{@tokens[:access]}" }
        let(:access_cookie) { @tokens[:access] }
        let(:csrf_token) { @tokens[:csrf] }

        before do
          payload = { user_id: user.id }
          session = JWTSessions::Session.new(payload: payload)
          @tokens = session.login
        end

        it 'CSRF is not required for cookie-less based auth' do
          request.headers[JWTSessions.access_header] = access_token
          post :create, params: user_params
          expect(response.code).to eq '200'
        end

        it do
          request.cookies[JWTSessions.access_cookie] = access_cookie
          post :create, params: user_params
          expect(response.code).to eq '401'
        end
      end
    end
  end
end
