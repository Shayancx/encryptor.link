require 'rails_helper'

RSpec.describe ZeroKnowledgeEncryption do
  let(:test_class) do
    Class.new do
      include ZeroKnowledgeEncryption
    end
  end

  let(:instance) { test_class.new }

  describe '#derive_key_from_password' do
    it 'derives consistent key from password' do
      key1 = instance.derive_key_from_password('testpassword')
      key2 = instance.derive_key_from_password('testpassword')

      expect(key1).to eq(key2)
      expect(key1.bytesize).to eq(32) # 256 bits
    end

    it 'derives different keys for different passwords' do
      key1 = instance.derive_key_from_password('password1')
      key2 = instance.derive_key_from_password('password2')

      expect(key1).not_to eq(key2)
    end
  end

  describe '#encrypt_with_key and #decrypt_with_key' do
    let(:key) { instance.derive_key_from_password('testpassword') }
    let(:data) { { message: 'Secret data', timestamp: Time.current.to_i } }

    it 'encrypts and decrypts data correctly' do
      encrypted = instance.encrypt_with_key(data, key)

      expect(encrypted).to be_a(String)
      expect(encrypted).not_to include('Secret data')

      decrypted = instance.decrypt_with_key(encrypted, key)

      expect(decrypted).to be_a(Hash)
      expect(decrypted['message']).to eq('Secret data')
      expect(decrypted['timestamp']).to eq(data[:timestamp])
    end

    it 'returns nil for empty data' do
      expect(instance.encrypt_with_key(nil, key)).to be_nil
      expect(instance.encrypt_with_key('', key)).to be_nil
      expect(instance.decrypt_with_key(nil, key)).to be_nil
      expect(instance.decrypt_with_key('', key)).to be_nil
    end

    it 'fails to decrypt with wrong key' do
      encrypted = instance.encrypt_with_key(data, key)
      wrong_key = instance.derive_key_from_password('wrongpassword')

      expect(instance.decrypt_with_key(encrypted, wrong_key)).to be_nil
    end

    it 'produces different ciphertext for same data' do
      encrypted1 = instance.encrypt_with_key(data, key)
      encrypted2 = instance.encrypt_with_key(data, key)

      expect(encrypted1).not_to eq(encrypted2)

      # But both decrypt to same data
      expect(instance.decrypt_with_key(encrypted1, key)).to eq(instance.decrypt_with_key(encrypted2, key))
    end
  end
end
