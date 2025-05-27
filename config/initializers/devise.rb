# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = "noreply@encryptor.link"

  require "devise/orm/active_record"

  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [ :http_auth ]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.timeout_in = 30.minutes
  config.lock_strategy = :failed_attempts
  config.unlock_keys = [ :email ]
  config.unlock_strategy = :both
  config.maximum_attempts = 5
  config.unlock_in = 1.hour
  config.reset_password_within = 6.hours
  config.sign_in_after_reset_password = true

  # Enable trackable for login history
  config.skip_session_storage = []

  # Configure the default scope
  config.scoped_views = true
  config.default_scope = :user
  config.sign_out_via = :delete

  # ==> Configuration for :timeoutable
  config.timeout_in = 30.minutes

  # ==> Configuration for :lockable
  config.lock_strategy = :failed_attempts
  config.unlock_keys = [ :email ]
  config.unlock_strategy = :both
  config.maximum_attempts = 5
  config.unlock_in = 1.hour
  config.last_attempt_warning = true

  # Configure sign out to be secure
  config.sign_out_via = :delete

  # Configure the parent controller for Devise controllers
  config.parent_controller = "ApplicationController"
end
