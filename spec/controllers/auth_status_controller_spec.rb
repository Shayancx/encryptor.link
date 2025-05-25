require 'rails_helper'

RSpec.describe AuthStatusController, type: :controller do
  describe 'GET #check' do
    context 'when user is authenticated' do
      let(:user) { create(:user) }

      before do
        # Simulate user authentication
        allow(controller).to receive(:authenticated?).and_return(true)
        allow(controller).to receive(:Current).and_return(double(user: user))
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
      before do
        allow(controller).to receive(:authenticated?).and_return(false)
      end

      it 'returns unauthenticated status' do
        get :check, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response['authenticated']).to be false
        expect(json_response['user_id']).to be_nil
      end
    end
  end
end
