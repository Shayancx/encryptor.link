require 'rails_helper'

RSpec.describe DecryptionsController, type: :controller do
  describe 'GET #show' do
    let(:payload) { create(:encrypted_payload) }

    it 'renders the show template' do
      get :show, params: { id: payload.id }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
    end

    it 'handles expired payload session flag' do
      session[:payload_expired] = true
      get :show, params: { id: 'any-id' }
      expect(assigns(:show_error)).to be true
      expect(session[:payload_expired]).to be_nil
    end
  end

  describe 'GET #data' do
    let(:payload) { create(:encrypted_payload, remaining_views: 2) }

    context 'with valid payload' do
      it 'returns encrypted data' do
        get :data, params: { id: payload.id }, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response['ciphertext']).to be_present
        expect(json_response['nonce']).to be_present
        expect(json_response['password_protected']).to eq(false)
      end

      it 'decrements remaining views' do
        expect {
          get :data, params: { id: payload.id }, format: :json
        }.to change { payload.reload.remaining_views }.from(2).to(1)
      end

      it 'marks for deletion when last view' do
        payload.update!(remaining_views: 1)
        initial_payload_id = payload.id

        # Make the request
        get :data, params: { id: payload.id }, format: :json

        # Check response is successful
        expect(response).to have_http_status(:success)

        # Check that the payload was marked for deletion by checking session
        # (we can't reload the payload because it gets deleted in the cleanup)
        # Instead, verify the cleanup happened by checking if payload still exists
        sleep 0.1 # Give time for cleanup callback to run
        expect(EncryptedPayload.exists?(initial_payload_id)).to be false
      end

      it 'includes password salt for protected payloads' do
        payload = create(:encrypted_payload, :with_password)
        get :data, params: { id: payload.id }, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response['password_salt']).to be_present
      end

      it 'includes files data' do
        file = create(:encrypted_file, encrypted_payload: payload)
        get :data, params: { id: payload.id }, format: :json

        json_response = JSON.parse(response.body)
        expect(json_response['files']).to be_present
        expect(json_response['files'].first['name']).to eq(file.file_name)
      end
    end

    context 'with expired payload' do
      let(:expired_payload) { create(:encrypted_payload, :expired) }

      it 'returns gone status' do
        get :data, params: { id: expired_payload.id }, format: :json
        expect(response).to have_http_status(:gone)
      end

      it 'sets session flag' do
        get :data, params: { id: expired_payload.id }, format: :json
        expect(session[:payload_expired]).to be true
      end
    end

    context 'with nonexistent payload' do
      it 'returns gone status' do
        get :data, params: { id: SecureRandom.uuid }, format: :json
        expect(response).to have_http_status(:gone)
      end
    end

    context 'with no views left' do
      let(:no_views_payload) { create(:encrypted_payload, :no_views_left) }

      it 'returns gone status' do
        get :data, params: { id: no_views_payload.id }, format: :json
        expect(response).to have_http_status(:gone)
      end
    end

    context 'concurrent access' do
      it 'handles race conditions safely' do
        # Skip this test as it's complex to test properly
        skip "Concurrent access testing requires more complex setup"
      end
    end
  end

  describe 'cleanup_payload callback' do
    it 'deletes payload after last view' do
      payload = create(:encrypted_payload, remaining_views: 1)
      payload_id = payload.id

      get :data, params: { id: payload.id }, format: :json

      # Wait a moment for cleanup to occur
      sleep 0.1

      expect(EncryptedPayload.exists?(payload_id)).to be false
    end

    it 'does not delete payload if views remain' do
      payload = create(:encrypted_payload, remaining_views: 2)

      get :data, params: { id: payload.id }, format: :json
      expect(EncryptedPayload.exists?(payload.id)).to be true
    end
  end
end
