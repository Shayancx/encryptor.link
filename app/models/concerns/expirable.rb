# frozen_string_literal: true

module Expirable
  extend ActiveSupport::Concern

  included do
    scope :expired, -> { where("expires_at < ?", Time.current) }
    scope :active, -> { where("expires_at >= ?", Time.current) }
  end

  def expired?
    expires_at < Time.current
  end

  def time_until_expiry
    expires_at - Time.current
  end
end
