require "digest"
class EncryptedPayload < ApplicationRecord
  has_many :encrypted_files, dependent: :destroy
  include Expirable

  before_save :calculate_checksums, if: :data_changed?

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

  def calculate_checksums
    if ciphertext_changed?
      self.ciphertext_checksum = Digest::SHA256.hexdigest(ciphertext)
    end
    if nonce_changed?
      self.nonce_checksum = Digest::SHA256.hexdigest(nonce)
    end
  end

  def data_changed?
    ciphertext_changed? || nonce_changed?
  end

  def verify_integrity
    return false unless ciphertext_checksum.present?

    current_ciphertext_checksum = Digest::SHA256.hexdigest(ciphertext)
    current_nonce_checksum = Digest::SHA256.hexdigest(nonce)

    ciphertext_checksum == current_ciphertext_checksum &&
      nonce_checksum == current_nonce_checksum
  end
end
