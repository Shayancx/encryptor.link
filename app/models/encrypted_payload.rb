class EncryptedPayload < ApplicationRecord
  include Expirable
  
  has_many :encrypted_files, dependent: :destroy
  has_one :destruction_certificate
  
  # Ciphertext can be blank if only files are attached
  validates :nonce, presence: true
  validates :expires_at, presence: true
  validates :remaining_views, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :max_views, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  
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
