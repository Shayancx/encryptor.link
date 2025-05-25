class UserMessageMetadata < ApplicationRecord
  belongs_to :user

  # Validations
  validates :message_id, presence: true, uniqueness: true
  validates :message_type, inclusion: { in: %w[text file mixed] }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where('original_expiry > ?', Time.current) }
  scope :expired, -> { where('original_expiry <= ?', Time.current) }

  # Default value for accessed_count
  after_initialize do
    self.accessed_count ||= 0
  end

  # Instance methods
  def expired?
    original_expiry <= Time.current
  end

  def increment_access_count!
    increment!(:accessed_count)
  end
end
