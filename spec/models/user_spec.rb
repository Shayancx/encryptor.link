require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email_address) }
    it { should validate_uniqueness_of(:email_address) }
    it { should allow_value('user@example.com').for(:email_address) }
    it { should_not allow_value('invalid-email').for(:email_address) }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:user_message_metadata).dependent(:destroy) }
    it { should have_one(:user_preference).dependent(:destroy) }
  end

  describe '.authenticate_by' do
    let(:user) { create(:user, email_address: 'Test@Example.com', password: 'password123') }

    it 'authenticates with correct credentials' do
      authenticated_user = User.authenticate_by(
        email_address: 'test@example.com',
        password: 'password123'
      )

      expect(authenticated_user).to eq(user)
      expect(authenticated_user.encryption_key).to be_present
    end

    it 'returns nil with incorrect password' do
      expect(User.authenticate_by(
        email_address: 'test@example.com',
        password: 'wrongpassword'
      )).to be_nil
    end

    it 'returns nil with non-existent email' do
      expect(User.authenticate_by(
        email_address: 'nonexistent@example.com',
        password: 'password123'
      )).to be_nil
    end

    it 'is case-insensitive for email' do
      authenticated_user = User.authenticate_by(
        email_address: 'TEST@EXAMPLE.COM',
        password: 'password123'
      )

      expect(authenticated_user).to eq(user)
    end
  end

  describe '#derive_key_from_password' do
    let(:user) { build(:user) }

    it 'derives encryption key from password' do
      key = user.derive_key_from_password('testpassword')

      expect(key).to be_present
      expect(key.bytesize).to eq(32)
    end
  end

  describe '#password_reset_token' do
    let(:user) { create(:user) }

    it 'generates a signed token' do
      token = user.password_reset_token
      expect(token).to be_present
    end
  end

  describe '.find_by_password_reset_token!' do
    let(:user) { create(:user) }
    let(:token) { user.password_reset_token }

    it 'finds user by valid token' do
      found_user = User.find_by_password_reset_token!(token)
      expect(found_user).to eq(user)
    end

    it 'raises error for invalid token' do
      expect {
        User.find_by_password_reset_token!('invalid-token')
      }.to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
    end
  end

  describe 'email normalization' do
    it 'downcases email before saving' do
      user = create(:user, email_address: 'UPPERCASE@EXAMPLE.COM')
      expect(user.reload.email_address).to eq('uppercase@example.com')
    end
  end
end
