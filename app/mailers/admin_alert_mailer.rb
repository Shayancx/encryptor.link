class AdminAlertMailer < ApplicationMailer
  default to: -> { ENV['ADMIN_ALERT_EMAIL'] || 'admin@example.com' }

  def security_alert(severity:, title:, details:, ip_address: nil)
    @severity = severity
    @title = title
    @details = details
    @ip_address = ip_address
    mail(subject: "Security Alert: #{title}")
  end
end
