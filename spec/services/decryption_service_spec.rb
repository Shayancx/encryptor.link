# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DecryptionService do
  let(:payload) { create(:encrypted_payload, remaining_views: 2) }
  subject { described_class.new(payload.id) }

  describe '#retrieve_data' do
    context 'with valid payload' do
      it 'returns encrypted data' do
        data = subject.retrieve_data
        expect(data[:ciphertext]).to be_present
        expect(data[:nonce]).to be_present
      end

      it 'decrements remaining views' do
        expect { subject.retrieve_data }.to change { payload.reload.remaining_views }.by(-1)
      end

      it 'includes files data' do
        create(:encrypted_file, encrypted_payload: payload)
        data = subject.retrieve_data
        expect(data[:files]).to be_present
        expect(data[:files].first[:name]).to be_present
      end
    end

    context 'with expired payload' do
      let(:expired_payload) { create(:encrypted_payload, expires_at: 1.hour.ago) }
      subject { described_class.new(expired_payload.id) }

      it 'returns nil' do
        expect(subject.retrieve_data).to be_nil
      end
    end

    context 'with no views left' do
      before { payload.update!(remaining_views: 0) }

      it 'returns nil' do
        expect(subject.retrieve_data).to be_nil
      end
    end
  end

  describe '#payload_info' do
    it 'returns payload information' do
      info = subject.payload_info
      expect(info[:exists]).to be true
      expect(info[:password_protected]).to be false
      expect(info[:expired]).to be false
    end

    context 'with nonexistent payload' do
      subject { described_class.new(SecureRandom.uuid) }

      it 'returns exists: false' do
        info = subject.payload_info
        expect(info[:exists]).to be false
      end
    end
  end

  describe '#retrieve_data cleanup' do
    it 'destroys payload on last view' do
      payload = create(:encrypted_payload, remaining_views: 1)
      service = described_class.new(payload.id)
      expect {
        service.retrieve_data
      }.to change { EncryptedPayload.exists?(payload.id) }.from(true).to(false)
    end
  end
end
