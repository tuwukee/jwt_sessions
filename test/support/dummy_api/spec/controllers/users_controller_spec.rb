# frozen_string_literal: true

describe UsersController do
  let(:password) { 'password123' }
  let!(:user) { create(:user) }

  describe 'GET #show' do
    before do
      payload = { user_id: user.id }
      session = JWTSessions::Session.new(payload: payload, refresh_payload: payload)
      @tokens = session.login
    end

    context 'success' do
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
  end
end
