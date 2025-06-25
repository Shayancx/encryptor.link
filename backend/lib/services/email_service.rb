# frozen_string_literal: true

require 'net/smtp'
require 'mail'

class EmailService
  class << self
    def send_password_reset_email(email, reset_token)
      return false unless Environment.email_enabled?

      begin
        reset_url = "#{Environment.frontend_url}/reset-password?token=#{reset_token}"

        mail = Mail.new do
          from     Environment.smtp_config[:from]
          to       email
          subject  'Reset Your Encryptor.link Password'

          text_part do
            body <<~TEXT
              Hello,

              You have requested to reset your password for Encryptor.link.

              Please click the following link to reset your password:
              #{reset_url}

              This link will expire in 1 hour.

              If you did not request this password reset, please ignore this email.

              Best regards,
              The Encryptor.link Team
            TEXT
          end

          html_part do
            content_type 'text/html; charset=UTF-8'
            body <<~HTML
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <title>Reset Your Password</title>
                <style>
                  body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                  .header { background: #f8f9fa; padding: 20px; text-align: center; border-radius: 8px; }
                  .content { padding: 20px 0; }
                  .button { display: inline-block; padding: 12px 24px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; margin: 20px 0; }
                  .footer { font-size: 12px; color: #666; margin-top: 30px; }
                </style>
              </head>
              <body>
                <div class="container">
                  <div class="header">
                    <h1>🔐 Encryptor.link</h1>
                    <h2>Password Reset Request</h2>
                  </div>
              #{'    '}
                  <div class="content">
                    <p>Hello,</p>
              #{'      '}
                    <p>You have requested to reset your password for your Encryptor.link account.</p>
              #{'      '}
                    <p>Please click the button below to reset your password:</p>
              #{'      '}
                    <a href="#{reset_url}" class="button">Reset Password</a>
              #{'      '}
                    <p>Alternatively, you can copy and paste this link into your browser:</p>
                    <p><a href="#{reset_url}">#{reset_url}</a></p>
              #{'      '}
                    <p><strong>This link will expire in 1 hour.</strong></p>
              #{'      '}
                    <p>If you did not request this password reset, please ignore this email. Your password will remain unchanged.</p>
              #{'      '}
                    <p>Best regards,<br>The Encryptor.link Team</p>
                  </div>
              #{'    '}
                  <div class="footer">
                    <p>This email was sent from an automated system. Please do not reply to this email.</p>
                  </div>
                </div>
              </body>
              </html>
            HTML
          end
        end

        # Configure SMTP
        smtp_config = Environment.smtp_config
        if smtp_config[:user] && smtp_config[:password]
          mail.delivery_method :smtp, {
            address: smtp_config[:host],
            port: smtp_config[:port],
            user_name: smtp_config[:user],
            password: smtp_config[:password],
            authentication: 'plain',
            enable_starttls_auto: true
          }
        else
          # For development without authentication
          mail.delivery_method :smtp, {
            address: smtp_config[:host],
            port: smtp_config[:port]
          }
        end

        mail.deliver!
        true
      rescue StandardError => e
        puts "Email delivery failed: #{e.message}" if Environment.development?
        false
      end
    end

    def send_welcome_email(email)
      return false unless Environment.email_enabled?

      begin
        mail = Mail.new do
          from     Environment.smtp_config[:from]
          to       email
          subject  'Welcome to Encryptor.link!'

          text_part do
            body <<~TEXT
              Welcome to Encryptor.link!

              Your account has been successfully created. You can now:

              • Upload files up to 4GB (vs 100MB for guests)
              • View your upload history
              • Manage your encrypted files

              Start encrypting your data securely at: #{Environment.frontend_url}

              Best regards,
              The Encryptor.link Team
            TEXT
          end

          html_part do
            content_type 'text/html; charset=UTF-8'
            body <<~HTML
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <title>Welcome to Encryptor.link</title>
                <style>
                  body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                  .header { background: #f8f9fa; padding: 20px; text-align: center; border-radius: 8px; }
                  .content { padding: 20px 0; }
                  .feature { background: #f8f9fa; padding: 15px; margin: 10px 0; border-radius: 4px; }
                  .button { display: inline-block; padding: 12px 24px; background: #28a745; color: white; text-decoration: none; border-radius: 4px; margin: 20px 0; }
                </style>
              </head>
              <body>
                <div class="container">
                  <div class="header">
                    <h1>🔐 Welcome to Encryptor.link!</h1>
                  </div>
              #{'    '}
                  <div class="content">
                    <p>Thank you for creating an account with Encryptor.link!</p>
              #{'      '}
                    <p>Your account is now active and you have access to premium features:</p>
              #{'      '}
                    <div class="feature">
                      <strong>🚀 Enhanced Upload Limits:</strong> Upload files up to 4GB (vs 100MB for guests)
                    </div>
              #{'      '}
                    <div class="feature">
                      <strong>📁 File Management:</strong> View your upload history and manage encrypted files
                    </div>
              #{'      '}
                    <div class="feature">
                      <strong>🔒 Secure Storage:</strong> All your data remains zero-knowledge encrypted
                    </div>
              #{'      '}
                    <a href="#{Environment.frontend_url}/encrypt" class="button">Start Encrypting</a>
              #{'      '}
                    <p>Questions? Visit our <a href="#{Environment.frontend_url}">website</a> for more information.</p>
              #{'      '}
                    <p>Best regards,<br>The Encryptor.link Team</p>
                  </div>
                </div>
              </body>
              </html>
            HTML
          end
        end

        # Configure SMTP
        smtp_config = Environment.smtp_config
        if smtp_config[:user] && smtp_config[:password]
          mail.delivery_method :smtp, {
            address: smtp_config[:host],
            port: smtp_config[:port],
            user_name: smtp_config[:user],
            password: smtp_config[:password],
            authentication: 'plain',
            enable_starttls_auto: true
          }
        else
          mail.delivery_method :smtp, {
            address: smtp_config[:host],
            port: smtp_config[:port]
          }
        end

        mail.deliver!
        true
      rescue StandardError => e
        puts "Welcome email delivery failed: #{e.message}" if Environment.development?
        false
      end
    end
  end
end
