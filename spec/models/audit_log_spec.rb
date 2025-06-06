require 'rails_helper'

RSpec.describe AuditLog, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:event_type) }
    it { should validate_presence_of(:severity) }
  end
end
