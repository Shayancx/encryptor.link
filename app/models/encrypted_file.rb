class EncryptedFile < ApplicationRecord
  belongs_to :encrypted_payload

  validates :file_data, :file_name, :file_size, presence: true
  validate :file_size_within_limit

  private
  def file_size_within_limit
    max_size = 1000.megabytes
    if file_size && file_size > max_size
      errors.add(:file_size, "cannot exceed 1000MB")
    end
  end
end
