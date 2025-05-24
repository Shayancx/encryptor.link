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
      # Create encrypted files with payloads
      payload1 = create(:encrypted_payload)
      payload2 = create(:encrypted_payload)
      file1 = create(:encrypted_file, encrypted_payload: payload1)
      file2 = create(:encrypted_file, encrypted_payload: payload2)

      # Store the file IDs before deletion
      file1_id = file1.id
      file2_id = file2.id
      payload1_id = payload1.id
      payload2_id = payload2.id

      # Use raw SQL to delete payloads without triggering Rails callbacks
      # This simulates orphaned files that could occur due to database issues
      ActiveRecord::Base.connection.execute(
        "DELETE FROM encrypted_payloads WHERE id IN ('#{payload1_id}', '#{payload2_id}')"
      )

      # Verify files still exist (are orphaned)
      expect(EncryptedFile.where(id: [file1_id, file2_id]).count).to eq(2)
      expect(EncryptedPayload.where(id: [payload1_id, payload2_id]).count).to eq(0)

      # Run cleanup - should remove orphaned files
      expect {
        described_class.new.perform
      }.to change(EncryptedFile, :count).by(-2)

      # Verify orphaned files were deleted
      expect(EncryptedFile.where(id: [file1_id, file2_id]).count).to eq(0)
    end
  end
end
