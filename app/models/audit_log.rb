require 'csv'

class AuditLog < ApplicationRecord
  belongs_to :payload, class_name: 'EncryptedPayload', foreign_key: 'payload_id', optional: true

  validates :event_type, presence: true
  validates :severity, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << %w[id event_type endpoint ip_address severity created_at]
      find_each do |log|
        csv << [log.id, log.event_type, log.endpoint, log.ip_address, log.severity, log.created_at]
      end
    end
  end
end
