require 'rails_helper'

RSpec.describe DestructionCertificate, type: :model do
  describe 'associations' do
    it { should belong_to(:encrypted_payload).optional }
  end

  describe 'callbacks' do
    it 'generates certificate data before create' do
      payload = create(:encrypted_payload)
      certificate = DestructionCertificate.create!(encrypted_payload: payload, destruction_reason: 'test')
      expect(certificate.certificate_id).to be_present
      expect(certificate.certificate_hash).to be_present
    end
  end
end
