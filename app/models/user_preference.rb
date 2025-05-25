class UserPreference < ApplicationRecord
  belongs_to :user

  # Validations
  validates :default_ttl, numericality: { greater_than: 0, less_than_or_equal_to: 604800 } # Max 7 days
  validates :default_views, numericality: { greater_than: 0, less_than_or_equal_to: 5 }
  validates :theme_preference, inclusion: { in: %w[light dark auto] }
end
