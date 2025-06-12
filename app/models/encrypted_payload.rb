class EncryptedPayload < ApplicationRecord
  include Expirable
  
  has_many :encrypted_files, dependent: :destroy
  has_one :destruction_certificate
  
  validates :ciphertext, presence: true
  validates :nonce, presence: true
  validates :expires_at, presence: true
  validates :remaining_views, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  
  before_validation :set_defaults, on: :create
  
  private
  
  def set_defaults
    self.nonce ||= SecureRandom.random_bytes(12)
    self.expires_at ||= 7.days.from_now
    self.remaining_views ||= 1
    self.max_views ||= self.remaining_views
    self.burn_after_reading ||= false
    self.password_protected ||= false
  end
end
