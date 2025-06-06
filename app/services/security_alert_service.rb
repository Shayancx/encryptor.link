class SecurityAlertService
  ALERT_THRESHOLDS = {
    failed_logins: { count: 10, window: 1.hour },
    rate_limit_hits: { count: 50, window: 15.minutes },
    payload_enumeration: { count: 30, window: 5.minutes },
    suspicious_activity: { count: 5, window: 1.hour }
  }.freeze

  def self.check_and_alert(event_type, ip_address, metadata = {})
    case event_type
    when AuditService::EVENTS[:admin_login_failed]
      check_failed_logins(ip_address)
    when AuditService::EVENTS[:rate_limit_exceeded]
      check_rate_limit_abuse(ip_address)
    when AuditService::EVENTS[:payload_accessed]
      check_payload_enumeration(ip_address, metadata)
    when AuditService::EVENTS[:suspicious_activity]
      send_immediate_alert(ip_address, metadata)
    end
  end

  class << self
    private

    def check_failed_logins(ip_address)
      threshold = ALERT_THRESHOLDS[:failed_logins]
      recent_failures = AuditLog.where(
        event_type: AuditService::EVENTS[:admin_login_failed],
        ip_address: ip_address,
        created_at: threshold[:window].ago..Time.current
      ).count

      if recent_failures >= threshold[:count]
        send_alert(
          severity: "high",
          title: "Brute Force Attack Detected",
          details: "#{recent_failures} failed login attempts from #{ip_address}",
          ip_address: ip_address
        )
      end
    end

    def check_rate_limit_abuse(ip_address)
      threshold = ALERT_THRESHOLDS[:rate_limit_hits]
      hits = AuditLog.where(
        event_type: AuditService::EVENTS[:rate_limit_exceeded],
        ip_address: ip_address,
        created_at: threshold[:window].ago..Time.current
      ).count

      if hits >= threshold[:count]
        send_alert(
          severity: "medium",
          title: "Rate Limit Abuse",
          details: "#{hits} rate limit triggers from #{ip_address}",
          ip_address: ip_address
        )
      end
    end

    def check_payload_enumeration(ip_address, metadata)
      threshold = ALERT_THRESHOLDS[:payload_enumeration]
      count = AuditLog.where(
        event_type: AuditService::EVENTS[:payload_accessed],
        ip_address: ip_address,
        created_at: threshold[:window].ago..Time.current
      ).select(:payload_id).distinct.count

      if count >= threshold[:count]
        send_alert(
          severity: "high",
          title: "Payload Enumeration Detected",
          details: "#{count} different payloads accessed from #{ip_address}",
          ip_address: ip_address
        )
      end
    end

    def send_immediate_alert(ip, metadata)
      send_alert(
        severity: "critical",
        title: "Suspicious Activity Detected",
        details: metadata.to_s,
        ip_address: ip
      )
    end

    def send_alert(severity:, title:, details:, ip_address: nil)
      AdminAlertMailer.security_alert(
        severity: severity,
        title: title,
        details: details,
        ip_address: ip_address
      ).deliver_now

      if ENV["SLACK_SECURITY_WEBHOOK"].present?
        SlackNotificationJob.perform_later(
          webhook_url: ENV["SLACK_SECURITY_WEBHOOK"],
          message: "\u1F6A8 #{severity.upcase}: #{title}\n#{details}"
        )
      end

      AuditService.log(
        event_type: AuditService::EVENTS[:security_alert_sent],
        metadata: {
          alert_severity: severity,
          alert_title: title,
          alert_details: details,
          target_ip: ip_address
        },
        severity: "warning"
      )
    end
  end
end
