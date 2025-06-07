class AccountPgpChallenge < ApplicationRecord
  belongs_to :account

  before_create :generate_nonce, :set_expiration

  private

  def generate_nonce
    self.nonce = SecureRandom.hex(32)
  end

  def set_expiration
    self.expires_at = 5.minutes.from_now
  end
end
