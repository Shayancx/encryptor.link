class Message < ApplicationRecord
  has_many :encrypted_files, dependent: :destroy
  
  validates :encrypted_data, presence: true
  
  # Rails 8 compatible serialization
  serialize :metadata
  
  before_create :set_expiration
  
  def increment_view_count
    self.view_count ||= 0
    self.view_count += 1
    
    # Mark as deleted if max views reached
    if self.max_views.present? && self.view_count >= self.max_views
      self.deleted = true
    end
    
    # Delete immediately if burn after reading
    if self.metadata&.dig('burn_after_reading') && self.view_count == 1
      self.deleted = true
    end
    
    save
  end
  
  def mark_as_deleted
    update(deleted: true)
  end
  
  def deleted?
    return true if deleted
    return true if expires_at && Time.current > expires_at
    return true if max_views && view_count >= max_views
    false
  end
  
  def max_views
    metadata&.dig('max_views')
  end
  
  private
  
  def set_expiration
    self.expires_at = metadata&.dig('expires_at')
    self.max_views = metadata&.dig('max_views').to_i if metadata&.dig('max_views').present?
  end
end
