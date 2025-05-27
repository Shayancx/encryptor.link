require 'rails_helper'

RSpec.describe Current do
  describe 'attributes' do
    it 'stores session' do
      session = create(:session)
      Current.session = session
      expect(Current.session).to eq(session)
    end

    it 'stores encryption key' do
      key = 'test-encryption-key'
      Current.encryption_key = key
      expect(Current.encryption_key).to eq(key)
    end

    it 'delegates user to session' do
      user = create(:user)
      session = create(:session, user: user)
      Current.session = session
      expect(Current.user).to eq(user)
    end

    it 'handles nil session for user delegation' do
      Current.session = nil
      expect(Current.user).to be_nil
    end
  end

  describe '#user=' do
    it 'sets user and preserves encryption key' do
      user = create(:user)
      user.encryption_key = 'test-key'

      Current.user = user

      expect(Current.encryption_key).to eq('test-key')
    end

    it 'clears encryption key when user is nil' do
      Current.encryption_key = 'existing-key'
      Current.user = nil

      expect(Current.encryption_key).to be_nil
    end
  end
end
