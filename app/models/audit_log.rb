class AuditLog < ApplicationRecord
  validates :event_type, presence: true
  validates :severity, presence: true
end
