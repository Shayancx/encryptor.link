class AdminUser < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: %w[super_admin audit_viewer] }

  scope :active, -> { where(active: true) }

  def can_view_audit_logs?
    %w[super_admin audit_viewer].include?(role)
  end

  def can_manage_admins?
    role == 'super_admin'
  end

  def can_export_audit_logs?
    role == 'super_admin'
  end
end
