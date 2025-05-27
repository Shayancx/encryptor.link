require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'factory' do
    it 'creates a valid session' do
      session = create(:session)
      expect(session).to be_valid
      expect(session.user).to be_present
      expect(session.ip_address).to be_present
      expect(session.user_agent).to be_present
    end
  end
end
