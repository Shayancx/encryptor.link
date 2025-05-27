class Current < ActiveSupport::CurrentAttributes
  attribute :session, :encryption_key
  delegate :user, to: :session, allow_nil: true

  def user=(user)
    super
    # Store encryption key in current attributes
    self.encryption_key = user&.encryption_key
  end
end
