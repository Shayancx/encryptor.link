class AuditService
  EVENTS = {
    payload_created: 'payload_created',
    payload_accessed: 'payload_accessed',
    payload_expired: 'payload_expired',
    rate_limit_hit: 'rate_limit_hit',
    suspicious_activity: 'suspicious_activity',
    system_cleanup: 'system_cleanup'
  }.freeze

  def self.log(event_type:, request: nil, payload_id: nil, metadata: {}, severity: 'info')
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
end
