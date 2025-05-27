require 'rails_helper'

RSpec.describe UserPreference, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_numericality_of(:default_ttl).is_greater_than(0).is_less_than_or_equal_to(604800) }
    it { should validate_numericality_of(:default_views).is_greater_than(0).is_less_than_or_equal_to(5) }
    it { should validate_inclusion_of(:theme_preference).in_array(%w[light dark auto]) }
  end

  describe 'factory' do
    it 'creates a valid preference' do
      user = create(:user)
      preference = build(:user_preference, user: user)
      expect(preference).to be_valid
    end
  end
end
