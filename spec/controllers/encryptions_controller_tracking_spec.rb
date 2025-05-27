require 'rails_helper'

RSpec.describe EncryptionsController, type: :controller do
  let(:user) { create(:user) }
  let(:user_session) { create(:session, user: user) }
  let(:encryption_key) { user.derive_key_from_password('password123') }

  let(:valid_params) do
    {
      ciphertext: Base64.strict_encode64('encrypted_data'),
      nonce: Base64.strict_encode64(SecureRandom.random_bytes(12)),
      ttl: 3600,
      views: 1,
      password_protected: false
    }
  end

  describe 'POST #create with user tracking' do
    before do
      cookies.signed[:session_id] = user_session.id
      allow(Current).to receive(:user).and_return(user)
      allow(Current).to receive(:encryption_key).and_return(encryption_key)
    end

    it 'tracks message when user is authenticated and tracking enabled' do
      params = valid_params.merge(
        track_message: "true",
        message_label: "Important Document",
        primary_filename: "contract.pdf"
      )

      expect {
        post :create, params: params, format: :json
      }.to change(UserMessageMetadata, :count).by(1)

      metadata = UserMessageMetadata.last
      expect(metadata.user).to eq(user)
      expect(metadata.message_type).to eq('text')

      # Decrypt and verify label
      metadata.decrypt_metadata(encryption_key)
      expect(metadata.label).to eq("Important Document")
    end

    it 'does not track when tracking disabled' do
      params = valid_params.merge(track_message: "false")

      expect {
        post :create, params: params, format: :json
      }.not_to change(UserMessageMetadata, :count)
    end

    it 'does not track when user not authenticated' do
      allow(Current).to receive(:user).and_return(nil)

      params = valid_params.merge(track_message: "true")

      expect {
        post :create, params: params, format: :json
      }.not_to change(UserMessageMetadata, :count)
    end

    it 'determines correct message type for mixed content' do
      params = valid_params.merge(
        track_message: "true",
        files: [ {
          data: Base64.strict_encode64('file_content'),
          name: 'test.txt',
          type: 'text/plain',
          size: 100
        } ]
      )

      post :create, params: params, format: :json

      metadata = UserMessageMetadata.last
      expect(metadata.message_type).to eq('mixed')
    end
  end
end
