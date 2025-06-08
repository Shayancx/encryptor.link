class EncryptedPayload < ApplicationRecord
  has_many :encrypted_files, dependent: :destroy
  include Expirable

  validates :expires_at, presence: true
  validates :remaining_views, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validate :ttl_within_limit, if: -> { persisted? }

  # Password related validations
  validates :password_salt, presence: true, if: -> { password_protected? }

  private
  def ttl_within_limit
    max_expiry = created_at + 7.days
    if expires_at > max_expiry
      errors.add(:expires_at, "cannot exceed 7 days")
    end
  end
end
