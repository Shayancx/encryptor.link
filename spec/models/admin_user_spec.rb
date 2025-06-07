require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  subject { build(:admin_user) }

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it do
      create(:admin_user, email: subject.email)
      should validate_uniqueness_of(:email)
    end
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(%w[super_admin audit_viewer]) }
  end

  describe '#can_view_audit_logs?' do
    it 'returns true for super_admin and audit_viewer' do
      expect(AdminUser.new(role: 'super_admin').can_view_audit_logs?).to be true
      expect(AdminUser.new(role: 'audit_viewer').can_view_audit_logs?).to be true
    end

    it 'returns false for other roles' do
      expect(AdminUser.new(role: 'other').can_view_audit_logs?).to be false
    end
  end

  describe '#can_manage_admins?' do
    it 'only allows super_admin' do
      expect(AdminUser.new(role: 'super_admin').can_manage_admins?).to be true
      expect(AdminUser.new(role: 'audit_viewer').can_manage_admins?).to be false
    end
  end

  describe '#can_export_audit_logs?' do
    it 'only allows super_admin' do
      expect(AdminUser.new(role: 'super_admin').can_export_audit_logs?).to be true
      expect(AdminUser.new(role: 'audit_viewer').can_export_audit_logs?).to be false
    end
  end
end
