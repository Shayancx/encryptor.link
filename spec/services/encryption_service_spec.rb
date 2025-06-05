# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EncryptionService do
  let(:valid_params) do
    {
      ciphertext: Base64.strict_encode64('encrypted_data'),
      nonce: Base64.strict_encode64(SecureRandom.random_bytes(12)),
      ttl: 3600,
      views: 1,
      password_protected: false
    }
  end

  describe '#create_payload' do

    subject { described_class.new(valid_params) }

    context 'with valid parameters' do
      it 'creates an encrypted payload' do
        expect { subject.create_payload }.to change(EncryptedPayload, :count).by(1)
      end

      it 'returns the created payload' do
        payload = subject.create_payload
        expect(payload).to be_a(EncryptedPayload)
        expect(payload).to be_persisted
      end

      it 'enforces maximum TTL' do
        service = described_class.new(valid_params.merge(ttl: 8.days.to_i))
        payload = service.create_payload
        expect(payload.expires_at).to be_within(1.minute).of(7.days.from_now)
      end
    end

    context 'with invalid parameters' do
      it 'raises error for missing nonce' do
        service = described_class.new(valid_params.except(:nonce))
        expect { service.create_payload }.to raise_error(EncryptionService::EncryptionError, /Nonce is required/)
      end

      it 'raises error for invalid views count' do
        service = described_class.new(valid_params.merge(views: 10))
        expect { service.create_payload }.to raise_error(EncryptionService::EncryptionError, /Views must be between/)
      end

      it 'raises error for invalid base64' do
        service = described_class.new(valid_params.merge(ciphertext: 'invalid!@#'))
        expect { service.create_payload }.to raise_error(EncryptionService::EncryptionError, /Invalid base64/)
      end
    end

    context 'with files' do
      let(:file_params) do
        valid_params.merge(
          files: [ {
            data: Base64.strict_encode64('file_content'),
            name: 'test.txt',
            type: 'text/plain',
            size: 100
          } ]
        )
      end

      it 'creates encrypted files' do
        service = described_class.new(file_params)
        expect { service.create_payload }.to change(EncryptedFile, :count).by(1)
      end

      it 'validates file size' do
        oversized_file = file_params[:files].first.merge(size: 1001.megabytes)
        service = described_class.new(file_params.merge(files: [ oversized_file ]))
        expect { service.create_payload }.to raise_error(EncryptionService::EncryptionError, /size exceeds/)
      end
    end
  end

  context 'parameter validation edge cases' do
      it 'requires ttl and views' do
        service = described_class.new(valid_params.except(:ttl))
        expect { service.create_payload }.to raise_error(EncryptionService::EncryptionError, /TTL and views are required/)
      end

      it 'rejects oversized ciphertext' do
        stub_const("#{described_class}::MAX_PAYLOAD_SIZE", 10)
        big_data = Base64.strict_encode64('a' * 11)
        service = described_class.new(valid_params.merge(ciphertext: big_data))
        expect { service.create_payload }.to raise_error(EncryptionService::EncryptionError, /Payload too large/)
      end

      it 'raises error for invalid password_salt' do
        service = described_class.new(valid_params.merge(password_protected: true, password_salt: '!!!'))
        expect { service.create_payload }.to raise_error(EncryptionService::EncryptionError, /Invalid base64/)
      end
    end

    context 'file validation edge cases' do
      it 'requires file name' do
        file = { data: Base64.strict_encode64('a'), size: 1, type: 'text/plain' }
        service = described_class.new(valid_params.merge(files: [file]))
        expect { service.create_payload }.to raise_error(EncryptionService::EncryptionError, /name is required/)
      end

      it 'requires file data' do
        file = { name: 'a.txt', size: 1, type: 'text/plain' }
        service = described_class.new(valid_params.merge(files: [file]))
        expect { service.create_payload }.to raise_error(EncryptionService::EncryptionError, /data is required/)
      end

      it 'creates multiple files' do
        files = [
          { data: Base64.strict_encode64('a'), name: 'a.txt', size: 1, type: 'text/plain' },
          { data: Base64.strict_encode64('b'), name: 'b.txt', size: 1, type: 'text/plain' }
        ]
        service = described_class.new(valid_params.merge(files: files))
        expect { service.create_payload }.to change(EncryptedFile, :count).by(2)
      end
    end
  end
