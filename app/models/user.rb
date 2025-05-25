class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :user_message_metadata, dependent: :destroy
  has_one :user_preference, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true, format: { with: /\A[^@\s]+@[^@\s]+\z/, message: "must be a valid email address" }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  before_save :downcase_email_address

  def self.authenticate_by(params)
    user = find_by(email_address: params[:email_address]&.downcase)
    return user if user && user.authenticate(params[:password])
    nil
  end

  def password_reset_token
    signed_id expires_in: 15.minutes, purpose: :password_reset
  end

  def self.find_by_password_reset_token!(token)
    find_signed!(token, purpose: :password_reset)
  end

  private

  def downcase_email_address
    self.email_address = email_address.downcase if email_address.present?
  end
end
