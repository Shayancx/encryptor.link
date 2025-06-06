require "digest"
class EncryptedFile < ApplicationRecord
  belongs_to :encrypted_payload

  before_save :calculate_checksum, if: :file_data_changed?

  validates :file_data, :file_name, :file_size, presence: true
  validate :file_size_within_limit

  private

  def calculate_checksum
    self.file_data_checksum = Digest::SHA256.hexdigest(file_data) if file_data_changed?
  end

  def verify_integrity
    return false unless file_data_checksum.present?
    Digest::SHA256.hexdigest(file_data) == file_data_checksum
  end

  def file_size_within_limit
    max_size = 1000.megabytes
    if file_size && file_size > max_size
      errors.add(:file_size, "cannot exceed 1000MB")
    end
  end
end
