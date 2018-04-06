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

    context 'success' do
      let(:refresh_token) { "Bearer #{@tokens[:refresh]}" }
      before do
        request.headers[JWTSessions.refresh_header] = refresh_token
        post :create
      end

      it do
        expect(response).to be_successful
        expect(response_json.keys.sort).to eq ['access', 'csrf', 'refresh']
      end
    end
  end
end
