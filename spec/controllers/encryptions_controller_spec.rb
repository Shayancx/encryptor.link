require 'rails_helper'

RSpec.describe EncryptionsController, type: :controller do
  describe 'GET #new' do
    it 'renders the new template' do
      get :new
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        ciphertext: Base64.strict_encode64('encrypted_data'),
        nonce: Base64.strict_encode64(SecureRandom.random_bytes(12)),
        ttl: 3600,
        views: 1,
        password_protected: false
      }
    end

    context 'with valid parameters' do
      it 'creates an encrypted payload' do
        expect {
          post :create, params: valid_params, format: :json
        }.to change(EncryptedPayload, :count).by(1)
      end

      it 'returns the payload ID' do
        post :create, params: valid_params, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to be_present
        expect(json_response['password_protected']).to eq(false)
      end
    end

    context 'with password protection' do
      it 'creates password-protected payload' do
        params = valid_params.merge(
          password_protected: true,
          password_salt: Base64.strict_encode64(SecureRandom.random_bytes(16))
        )
        post :create, params: params, format: :json

        payload = EncryptedPayload.last
        expect(payload.password_protected).to be true
        expect(payload.password_salt).to be_present
      end
    end

    context 'with files' do
      it 'creates encrypted files' do
        params = valid_params.merge(
          files: [
            {
              data: Base64.strict_encode64('file_content'),
              name: 'test.txt',
              type: 'text/plain',
              size: 100
            }
          ]
        )

        expect {
          post :create, params: params, format: :json
        }.to change(EncryptedFile, :count).by(1)
      end
    end

    context 'with invalid parameters' do
      it 'returns error for missing nonce' do
        post :create, params: valid_params.except(:nonce), format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Nonce is required')
      end

      it 'returns error for invalid views count' do
        post :create, params: valid_params.merge(views: 10), format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'security validations' do
      it 'enforces maximum TTL of 7 days' do
        params = valid_params.merge(ttl: 8.days.to_i)
        post :create, params: params, format: :json

        payload = EncryptedPayload.last
        expect(payload.expires_at).to be <= 7.days.from_now + 1.minute
      end

      it 'enforces maximum views of 5' do
        params = valid_params.merge(views: 6)
        post :create, params: params, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
