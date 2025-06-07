require 'rails_helper'

RSpec.describe DestructionCertificateService do
  let(:payload) { create(:encrypted_payload) }

  describe '.generate_for_payload' do
    it 'creates a destruction certificate' do
      expect {
        DestructionCertificateService.generate_for_payload(payload, 'viewed')
      }.to change(DestructionCertificate, :count).by(1)
    end

    it 'returns a certificate object' do
      certificate = DestructionCertificateService.generate_for_payload(payload, 'viewed')
      expect(certificate).to be_a(DestructionCertificate)
      expect(certificate.certificate_id).to be_present
    end
  end

  describe '.verify_certificate' do
    it 'verifies a certificate hash' do
      certificate = DestructionCertificateService.generate_for_payload(payload, 'viewed')
      result = DestructionCertificateService.verify_certificate(certificate.certificate_hash)
      expect(result[:valid]).to be true
      expect(result[:certificate]).to eq(certificate)
    end

    it 'returns nil for unknown hash' do
      result = DestructionCertificateService.verify_certificate('deadbeef')
      expect(result).to be_nil
    end
  end
end
