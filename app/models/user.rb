class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :user_message_metadata, dependent: :destroy
  has_one :user_preference, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }

  # Virtual attribute for password confirmation
  attr_accessor :password_confirmation
  validates_confirmation_of :password, if: -> { new_record? || !password.nil? }

  # Callbacks
  after_create :create_default_preferences

  private

  def create_default_preferences
    UserPreference.create!(
      user: self,
      default_ttl: 86400,  # 1 day
      default_views: 1,
      theme_preference: 'auto'
    )
  end
end
