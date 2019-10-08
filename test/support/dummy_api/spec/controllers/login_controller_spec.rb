# frozen_string_literal: true

describe LoginController do
  let(:password) { 'password123' }
  let!(:user) { create(:user) }

  describe 'POST #create' do
    context 'success' do
      before { post :create, params: { email: user.email, password: password } }

      it do
        expect(response).to be_successful
        expect(response_json.keys.sort).to eq ['access', 'access_expires_at', 'csrf', 'refresh', 'refresh_expires_at']
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'success' do
      before do
        payload = { user_id: user.id }
        session = JWTSessions::Session.new(payload: payload, refresh_by_access_allowed: true)
        tokens = session.login
        request.headers[JWTSessions.access_header] = "Bearer #{tokens[:access]}"
        request.headers[JWTSessions.csrf_header] = tokens[:csrf]
        delete :destroy
      end

      it do
        expect(response).to be_successful
        expect(response_json).to eq 'ok'
      end
    end

    context 'success after refresh' do
      before do
        payload = { user_id: user.id }
        session = JWTSessions::Session.new(payload: payload, refresh_by_access_allowed: true)
        session.login

        session2 = JWTSessions::Session.new(payload: session.payload, refresh_by_access_allowed: true)
        tokens = session2.refresh_by_access_payload

        request.headers[JWTSessions.access_header] = "Bearer #{tokens[:access]}"
        request.headers[JWTSessions.csrf_header] = tokens[:csrf]
        delete :destroy
      end

      it do
        expect(response).to be_successful
        expect(response_json).to eq 'ok'
      end
    end
  end

  describe 'DELETE #destroy_by_refresh' do
    context 'success' do
      before do
        payload = { user_id: user.id }
        session = JWTSessions::Session.new(payload: payload)
        tokens = session.login
        request.headers[JWTSessions.refresh_header] = tokens[:refresh]
        request.headers[JWTSessions.csrf_header] = tokens[:csrf]
        delete :destroy_by_refresh
      end

      it do
        expect(response).to be_successful
        expect(response_json).to eq 'ok'
      end
    end

    context 'success after refresh' do
      before do
        payload = { user_id: user.id }
        session = JWTSessions::Session.new(payload: payload)
        tokens1 = session.login

        session2 = JWTSessions::Session.new(payload: payload)
        tokens2 = session2.refresh(tokens1[:refresh])

        request.headers[JWTSessions.refresh_header] = tokens1[:refresh]
        request.headers[JWTSessions.csrf_header] = tokens2[:csrf]
        delete :destroy_by_refresh
      end

      it do
        expect(response).to be_successful
        expect(response_json).to eq 'ok'
      end
    end
  end
end
