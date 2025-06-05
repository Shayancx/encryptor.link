require 'rails_helper'

RSpec.describe Expirable do
  let!(:expired) { create(:encrypted_payload, expires_at: 1.hour.ago) }
  let!(:active)  { create(:encrypted_payload, expires_at: 1.hour.from_now) }

  describe '.expired' do
    it 'returns only expired records' do
      expect(EncryptedPayload.expired).to include(expired)
      expect(EncryptedPayload.expired).not_to include(active)
    end
  end

  describe '.active' do
    it 'returns only active records' do
      expect(EncryptedPayload.active).to include(active)
      expect(EncryptedPayload.active).not_to include(expired)
    end
  end

  describe '#expired?' do
    it 'detects expiration state' do
      expect(expired.expired?).to be true
      expect(active.expired?).to be false
    end
  end

  describe '#time_until_expiry' do
    it 'calculates remaining time' do
      remaining = active.time_until_expiry
      expect(remaining).to be_within(5.seconds).of(1.hour)
    end
  end
end
