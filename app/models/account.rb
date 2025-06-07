class Account < ApplicationRecord
  include Rodauth::Rails.model
  enum :status, { unverified: 1, verified: 2, closed: 3 }

  validates :pgp_public_key, presence: true

  has_many :account_pgp_challenges, dependent: :delete_all
end
