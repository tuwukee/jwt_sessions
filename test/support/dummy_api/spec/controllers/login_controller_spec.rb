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
end
