require 'rails_helper'

RSpec.describe UserMessageMetadata, type: :model do
  let(:user) { create(:user) }
  let(:encryption_key) { user.derive_key_from_password('password123') }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:user_message_metadata, user: user) }

    it { should validate_presence_of(:message_id) }
    it { should validate_uniqueness_of(:message_id) }
    it { should validate_inclusion_of(:message_type).in_array(%w[text file mixed]).allow_nil(true) }
  end

  describe 'encryption methods' do
    let(:metadata) { build(:user_message_metadata, user: user) }

    it 'encrypts label and filename' do
      metadata.label = 'Test Label'
      metadata.filename = 'test.txt'

      metadata.encrypt_metadata(encryption_key)

      expect(metadata.encrypted_label).not_to eq('Test Label')
      expect(metadata.encrypted_label).to be_present
      expect(metadata.encrypted_filename).not_to eq('test.txt')
      expect(metadata.encrypted_filename).to be_present
    end

    it 'decrypts label and filename' do
      metadata.label = 'Test Label'
      metadata.filename = 'test.txt'
      metadata.encrypt_metadata(encryption_key)

      # Clear virtual attributes
      metadata.label = nil
      metadata.filename = nil

      # Decrypt
      metadata.decrypt_metadata(encryption_key)

      expect(metadata.label).to eq('Test Label')
      expect(metadata.filename).to eq('test.txt')
    end

    it 'handles nil encryption gracefully' do
      metadata.encrypt_metadata(encryption_key)

      expect(metadata.encrypted_label).to be_nil
      expect(metadata.encrypted_filename).to be_nil
    end

    it 'returns nil for wrong encryption key' do
      metadata.label = 'Test Label'
      metadata.encrypt_metadata(encryption_key)

      wrong_key = user.derive_key_from_password('wrongpassword')
      metadata.label = nil
      metadata.decrypt_metadata(wrong_key)

      expect(metadata.label).to be_nil
    end
  end

  describe 'scopes' do
    let!(:recent) { create(:user_message_metadata, user: user, created_at: 1.hour.ago) }
    let!(:old) { create(:user_message_metadata, user: user, created_at: 1.week.ago) }
    let!(:active) { create(:user_message_metadata, user: user, original_expiry: 1.day.from_now) }
    let!(:expired) { create(:user_message_metadata, user: user, original_expiry: 1.day.ago) }

    it 'returns recent messages first' do
      expect(UserMessageMetadata.recent.first).to eq(recent)
    end

    it 'returns active messages' do
      active_messages = UserMessageMetadata.active
      expect(active_messages).to include(active, recent, old)
      expect(active_messages).not_to include(expired)
    end

    it 'returns expired messages' do
      expired_messages = UserMessageMetadata.expired
      expect(expired_messages).to include(expired)
      expect(expired_messages).not_to include(active)
    end
  end

  describe '#expired?' do
    it 'returns false when no expiry' do
      metadata = build(:user_message_metadata, original_expiry: nil)
      expect(metadata.expired?).to be false
    end

    it 'returns true when expired' do
      metadata = build(:user_message_metadata, original_expiry: 1.day.ago)
      expect(metadata.expired?).to be true
    end

    it 'returns false when not expired' do
      metadata = build(:user_message_metadata, original_expiry: 1.day.from_now)
      expect(metadata.expired?).to be false
    end
  end

  describe '#increment_access_count!' do
    it 'increments the access count' do
      metadata = create(:user_message_metadata, user: user, accessed_count: 5)
      expect { metadata.increment_access_count! }.to change { metadata.reload.accessed_count }.from(5).to(6)
    end
  end

  describe '.page' do
    before do
      create_list(:user_message_metadata, 25, user: user)
    end

    it 'returns paginated results' do
      page1 = UserMessageMetadata.page(1)
      page2 = UserMessageMetadata.page(2)

      expect(page1.count).to eq(20)
      expect(page2.count).to eq(5)
      expect(page1.pluck(:id)).not_to match_array(page2.pluck(:id))
    end
  end
end
