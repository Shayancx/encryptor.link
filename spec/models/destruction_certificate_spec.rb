require 'rails_helper'

RSpec.describe DestructionCertificate, type: :model do
  describe 'associations' do
    it { should belong_to(:encrypted_payload).optional }
  end

  describe 'validations' do
    let(:certificate) { build(:destruction_certificate) }

    it 'validates presence of certificate_id after creation' do
      certificate.save
      expect(certificate.certificate_id).to be_present
    end

    it 'validates presence of certificate_hash after creation' do
      certificate.save
      expect(certificate.certificate_hash).to be_present
    end

    it 'validates presence of certificate_data after creation' do
      certificate.save
      expect(certificate.certificate_data).to be_present
    end
  end

  describe 'callbacks' do
    it 'generates certificate data before create' do
      payload = create(:encrypted_payload)
      certificate = DestructionCertificate.create!(
        encrypted_payload: payload,
        destruction_reason: 'test'
      )

      expect(certificate.certificate_id).to match(/^[a-f0-9]{64}$/)
      expect(certificate.certificate_hash).to match(/^[a-f0-9]{64}$/)

      data = JSON.parse(certificate.certificate_data)
      expect(data['payload_id']).to eq(payload.id)
      expect(data['server_signature']).to be_present
      expect(data['version']).to eq('1.0')
    end

    it 'handles missing signing key gracefully' do
      allow(Rails.application).to receive_message_chain(:credentials, :secret_key_base).and_return(nil)
      if Rails.application.respond_to?(:secrets)
        allow(Rails.application).to receive_message_chain(:secrets, :secret_key_base).and_return(nil)
      end
      allow(Rails.configuration).to receive(:secret_key_base).and_return(nil)

      payload = create(:encrypted_payload)

      expect {
        DestructionCertificate.create!(
          encrypted_payload: payload,
          destruction_reason: 'test'
        )
      }.to raise_error(DestructionCertificate::CertificateGenerationError)
    end
  end

  describe 'certificate integrity' do
    it 'generates unique certificates for each destruction' do
      payload = create(:encrypted_payload)

      cert1 = DestructionCertificate.create!(
        encrypted_payload: payload,
        destruction_reason: 'test1'
      )

      cert2 = DestructionCertificate.create!(
        encrypted_payload: payload,
        destruction_reason: 'test2'
      )

      expect(cert1.certificate_id).not_to eq(cert2.certificate_id)
      expect(cert1.certificate_hash).not_to eq(cert2.certificate_hash)
    end

    it 'includes timestamp in signature to prevent replay attacks' do
      payload = create(:encrypted_payload)

      Timecop.freeze(Time.current) do
        cert1 = DestructionCertificate.create!(
          encrypted_payload: payload,
          destruction_reason: 'test'
        )

        Timecop.travel(1.second) do
          cert2 = DestructionCertificate.create!(
            encrypted_payload: payload,
            destruction_reason: 'test'
          )

          data1 = JSON.parse(cert1.certificate_data)
          data2 = JSON.parse(cert2.certificate_data)

          expect(data1['server_signature']).not_to eq(data2['server_signature'])
        end
      end
    end
  end
end
