require 'rails_helper'

RSpec.describe EncryptedPayload, type: :model do
  describe 'associations' do
    it { should have_many(:encrypted_files).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:expires_at) }
    it { should validate_numericality_of(:remaining_views).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(5) }

    context 'when password_protected is true' do
      subject { build(:encrypted_payload, password_protected: true) }
      it { should validate_presence_of(:password_salt) }
    end

    context 'when password_protected is false' do
      subject { build(:encrypted_payload, password_protected: false) }
      it { should_not validate_presence_of(:password_salt) }
    end
  end

  describe 'custom validations' do
    context 'ttl_within_limit' do
      it 'allows expiration within 7 days' do
        payload = create(:encrypted_payload, expires_at: 6.days.from_now)
        expect(payload).to be_valid
      end

      it 'does not validate on new records' do
        payload = build(:encrypted_payload, expires_at: 8.days.from_now)
        expect(payload).to be_valid
      end
    end
  end

  describe 'security' do
    it 'generates unique IDs using UUID' do
      payload1 = create(:encrypted_payload)
      payload2 = create(:encrypted_payload)
      expect(payload1.id).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
      expect(payload1.id).not_to eq(payload2.id)
    end

    it 'stores binary data securely' do
      payload = create(:encrypted_payload)
      expect(payload.ciphertext).to be_a(String)
      expect(payload.ciphertext.encoding.name).to eq("ASCII-8BIT")
    end
  end
  describe 'ttl_within_limit' do
    it 'disallows expiration beyond 7 days for persisted records' do
      payload = create(:encrypted_payload, expires_at: 6.days.from_now)
      payload.expires_at = 8.days.from_now
      expect(payload).not_to be_valid
      expect(payload.errors[:expires_at]).to include('cannot exceed 7 days')
    end
  end
end
