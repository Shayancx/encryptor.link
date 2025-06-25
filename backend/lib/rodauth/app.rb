# frozen_string_literal: true

require 'rodauth'
require 'jwt'
require 'securerandom'

module RodauthApp
  def self.configure(app)
    app.plugin :rodauth, json: :only do
      enable :login, :logout, :create_account, :jwt

      # Database configuration
      db DB

      # JWT configuration
      jwt_secret ENV.fetch('JWT_SECRET') { SecureRandom.hex(32) }

      # Account configuration
      account_password_hash_column :password_hash
      accounts_table :accounts

      # Don't require email verification
      skip_status_checks? true

      # Password requirements
      password_meets_requirements? do |password|
        password.length >= 8 &&
          password =~ /[A-Z]/ &&
          password =~ /[a-z]/ &&
          password =~ /\d/
      end

      # JSON only mode
      only_json? true

      # Routes
      prefix '/api/auth'

      # Custom responses
      create_account_redirect { json_response(success: true, account_id: account_id) }
      login_redirect { json_response(success: true) }
      logout_redirect { json_response(success: true) }

      # JWT settings
      jwt_access_token_period 86_400 # 24 hours
    end
  end
end

# Mixin for Roda app
module RodauthMixin
  def self.included(base)
    base.class_eval do
      # Helper to check authentication
      def authenticated?
        return false unless rodauth.jwt_token

        begin
          rodauth.require_account
          true
        rescue StandardError
          false
        end
      end

      # Get current account safely
      def current_account
        return nil unless authenticated?

        @current_account ||= DB[:accounts].where(id: rodauth.account_id).first
      end

      # Get upload limit
      def upload_limit
        authenticated? ? 4 * 1024 * 1024 * 1024 : 100 * 1024 * 1024
      end
    end
  end
end
