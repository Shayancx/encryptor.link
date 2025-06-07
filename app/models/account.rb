class Account < ApplicationRecord
  include Rodauth::Rails.model
  enum :status, { unverified: 1, verified: 2, closed: 3 }

  validates :pgp_public_key, presence: true
  validates :pgp_fingerprint, presence: true, uniqueness: true

  before_validation :set_pgp_fingerprint

  has_many :account_pgp_challenges, dependent: :delete_all

  private

  def set_pgp_fingerprint
    return if pgp_public_key.blank?
    self.pgp_fingerprint = PgpService.fingerprint(pgp_public_key)
  end
end
