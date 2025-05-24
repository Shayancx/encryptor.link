require 'rails_helper'

RSpec.describe CleanupExpiredPayloadsJob, type: :job do
  describe '#perform' do
    it 'removes expired payloads' do
      expired = create_list(:encrypted_payload, 3, :expired)
      valid = create_list(:encrypted_payload, 2)

      expect {
        described_class.new.perform
      }.to change(EncryptedPayload, :count).by(-3)

      expect(EncryptedPayload.where(id: expired.map(&:id))).to be_empty
      expect(EncryptedPayload.where(id: valid.map(&:id)).count).to eq(2)
    end

    it 'removes payloads with no views left' do
      no_views = create_list(:encrypted_payload, 2, :no_views_left)

      expect {
        described_class.new.perform
      }.to change(EncryptedPayload, :count).by(-2)
    end

    it 'removes associated files' do
      payload = create(:encrypted_payload, :expired)
      create_list(:encrypted_file, 3, encrypted_payload: payload)

      expect {
        described_class.new.perform
      }.to change(EncryptedFile, :count).by(-3)
    end

    it 'logs cleanup results' do
      create_list(:encrypted_payload, 2, :expired)

      expect(Rails.logger).to receive(:info).with(/removed 2 expired payloads/)

      described_class.new.perform
    end

    it 'handles orphaned files' do
      # Create an encrypted file
      file = create(:encrypted_file)
      file_id = file.id

      # Delete the parent payload directly to create an orphan
      # Use delete instead of destroy to avoid cascade
      EncryptedPayload.where(id: file.encrypted_payload_id).delete_all

      # Verify file still exists (is orphaned)
      expect(EncryptedFile.exists?(file_id)).to be true

      # Run cleanup
      expect {
        described_class.new.perform
      }.to change(EncryptedFile, :count).by(-1)

      # Verify orphaned file was deleted
      expect(EncryptedFile.exists?(file_id)).to be false
    end
  end
end
