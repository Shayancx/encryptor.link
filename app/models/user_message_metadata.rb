class UserMessageMetadata < ApplicationRecord
  belongs_to :user

  # Validations
  validates :message_id, presence: true, uniqueness: true
  validates :message_type, inclusion: { in: %w[text file mixed] }, allow_nil: true

  # Scopes - defined as class methods to ensure they work
  def self.recent
    order(created_at: :desc)
  end

  def self.active
    where('original_expiry IS NULL OR original_expiry > ?', Time.current)
  end

  def self.expired
    where('original_expiry IS NOT NULL AND original_expiry <= ?', Time.current)
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
