# frozen_string_literal: true

describe LoginWithCookiesController do
  let(:password) { 'password123' }
  let!(:user) { create(:user) }

  describe 'POST #create' do
    context 'success' do
      before { post :create, params: { email: user.email, password: password } }

      it do
        expect(response).to be_successful
        expect(response_json.keys.sort).to eq ['access', 'access_expires_at', 'csrf', 'refresh', 'refresh_expires_at']
        expect(response.cookies.keys.sort).to eq ['jwt_access', 'jwt_refresh']
      end
    end
  end
end
