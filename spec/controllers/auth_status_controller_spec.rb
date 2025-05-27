require 'rails_helper'

RSpec.describe AuthStatusController, type: :controller do
  describe 'GET #check' do
    context 'when user is authenticated' do
      let(:user) { create(:user) }
      let(:user_session) { create(:session, user: user) }

      before do
        # Set up proper authentication
        cookies.signed[:session_id] = user_session.id
        allow(Current).to receive(:user).and_return(user)
      end

      it 'returns authenticated status with user info' do
        get :check, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response['authenticated']).to be true
        expect(json_response['user_id']).to eq(user.id)
        expect(json_response['email']).to eq(user.email_address)
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthenticated status' do
        get :check, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response['authenticated']).to be false
        expect(json_response['user_id']).to be_nil
      end
    end
  end
end
