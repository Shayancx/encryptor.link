class UserMessageMetadata < ApplicationRecord
  include ZeroKnowledgeEncryption

  belongs_to :user

  # Validations
  validates :message_id, presence: true, uniqueness: true
  validates :message_type, inclusion: { in: %w[text file mixed] }, allow_nil: true

  # Virtual attributes for decrypted data
  attr_accessor :label, :filename

  # Encrypt label and filename before saving
  def encrypt_metadata(encryption_key)
    if label.present?
      self.encrypted_label = encrypt_with_key({ label: label }, encryption_key)
    end

    if filename.present?
      self.encrypted_filename = encrypt_with_key({ filename: filename }, encryption_key)
    end
  end

  # Decrypt label and filename after loading
  def decrypt_metadata(encryption_key)
    if encrypted_label.present?
      decrypted = decrypt_with_key(encrypted_label, encryption_key)
      self.label = decrypted["label"] if decrypted
    end

    if encrypted_filename.present?
      decrypted = decrypt_with_key(encrypted_filename, encryption_key)
      self.filename = decrypted["filename"] if decrypted
    end
  end

  # Scopes
  def self.recent
    order(created_at: :desc)
  end

  def self.active
    where("original_expiry IS NULL OR original_expiry > ?", Time.current)
  end

  def self.expired
    where("original_expiry IS NOT NULL AND original_expiry <= ?", Time.current)
  end

  # Default value for accessed_count
  after_initialize do
    self.accessed_count ||= 0 if new_record?
  end

  # Instance methods
  def expired?
    return false if original_expiry.nil?
    original_expiry <= Time.current
  end

  def increment_access_count!
    increment!(:accessed_count)
  end

  # Simple pagination
  def self.page(page_number)
    page_number = (page_number || 1).to_i
    limit(20).offset((page_number - 1) * 20)
  end
end
