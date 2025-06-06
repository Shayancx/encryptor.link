class AuditService
  EVENTS = {
    # Existing events
    payload_created: 'payload_created',
    payload_accessed: 'payload_accessed',
    payload_expired: 'payload_expired',
    system_cleanup: 'system_cleanup',

    # Authentication events
    admin_login_success: 'admin_login_success',
    admin_login_failed: 'admin_login_failed',
    admin_logout: 'admin_logout',

    # Authorization events
    unauthorized_admin_access: 'unauthorized_admin_access',
    unauthorized_audit_access: 'unauthorized_audit_access',
    unauthorized_audit_export: 'unauthorized_audit_export',

    # Rate limiting events
    rate_limit_exceeded: 'rate_limit_exceeded',
    blocked_request: 'blocked_request',
    safelisted_request: 'safelisted_request',

    # Security events
    suspicious_activity: 'suspicious_activity',
    payload_enumeration_attempt: 'payload_enumeration_attempt',
    invalid_payload_access: 'invalid_payload_access',
    password_brute_force: 'password_brute_force',
    malformed_request: 'malformed_request',

    # Data events
    audit_log_cleanup: 'audit_log_cleanup',
    admin_created: 'admin_created',
    admin_deleted: 'admin_deleted',
    security_alert_sent: 'security_alert_sent',
    audit_log_viewed: 'audit_log_viewed'
  }.freeze

  def self.log(event_type:, request: nil, payload_id: nil, metadata: {}, severity: 'info')
    if request && suspicious_request?(request, event_type, metadata)
      severity = 'critical'
      original = event_type
      event_type = EVENTS[:suspicious_activity]
      metadata[:original_event] = original
      metadata[:threat_indicators] = detect_threat_indicators(request, metadata)
    end

    AuditLog.create!(
      event_type: event_type,
      endpoint: request&.path,
      payload_id: payload_id,
      ip_address: request&.ip,
      user_agent: request&.user_agent&.truncate(255),
      metadata: metadata,
      severity: severity
    )
  rescue => e
    Rails.logger.error "Failed to create audit log: #{e.message}"
  end

  class << self
    private

    def suspicious_request?(request, event_type, metadata)
      return true if event_type == EVENTS[:unauthorized_audit_access] && recent_failures_count(request.ip) > 5
      return true if event_type == EVENTS[:payload_accessed] && recent_unique_payloads_count(request.ip) > 20
      return true if metadata[:response_status] == 400 && request.content_length && request.content_length > 100.megabytes
      false
    end

    def detect_threat_indicators(request, metadata)
      indicators = []
      indicators << 'rapid_requests' if rapid_requests?(request.ip)
      indicators << 'invalid_user_agent' if invalid_user_agent?(request.user_agent)
      indicators << 'payload_enumeration' if payload_enumeration?(request.ip)
      indicators
    end

    def recent_failures_count(ip)
      AuditLog.where(event_type: EVENTS[:unauthorized_audit_access], ip_address: ip, created_at: 1.hour.ago..Time.current).count
    end

    def recent_unique_payloads_count(ip)
      AuditLog.where(event_type: EVENTS[:payload_accessed], ip_address: ip, created_at: 15.minutes.ago..Time.current).select(:payload_id).distinct.count
    end

    def rapid_requests?(ip)
      AuditLog.where(ip_address: ip, created_at: 1.minute.ago..Time.current).count > 100
    end

    def invalid_user_agent?(ua)
      ua.blank? || ua.length < 5
    end

    def payload_enumeration?(ip)
      recent_unique_payloads_count(ip) > 20
    end
  end
end
