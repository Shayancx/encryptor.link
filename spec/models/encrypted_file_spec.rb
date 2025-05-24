require 'rails_helper'

RSpec.describe EncryptedFile, type: :model do
  describe 'associations' do
    it { should belong_to(:encrypted_payload) }
  end

  describe 'validations' do
    it { should validate_presence_of(:file_data) }
    it { should validate_presence_of(:file_name) }
    it { should validate_presence_of(:file_size) }
  end

  describe 'file size validation' do
    it 'allows files up to 1000MB' do
      file = build(:encrypted_file, file_size: 1000.megabytes)
      expect(file).to be_valid
    end

    it 'rejects files over 1000MB' do
      file = build(:encrypted_file, file_size: 1001.megabytes)
      expect(file).not_to be_valid
      expect(file.errors[:file_size]).to include("cannot exceed 1000MB")
    end
  end
end
