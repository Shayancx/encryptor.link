class SecurityMonitoringJob < ApplicationJob
  queue_as :high_priority

  def perform
    check_anomalies
    check_system_health
    cleanup_old_tracking_data
  end

  private

  def check_anomalies
    unusual_ips = detect_unusual_ip_activity
    mass_payload_access = detect_mass_payload_access

    unusual_ips.each { |ip| SecurityAlertService.send_alert(severity: 'medium', title: 'Unusual IP Activity', details: 'High request volume', ip_address: ip) }
    mass_payload_access.each { |ip| SecurityAlertService.send_alert(severity: 'high', title: 'Payload Enumeration', details: 'Potential enumeration detected', ip_address: ip) }
  end

  def detect_unusual_ip_activity
    AuditLog.where(created_at: 1.hour.ago..Time.current)
            .group(:ip_address)
            .having('COUNT(*) > ?', 100)
            .pluck(:ip_address)
  end

  def detect_mass_payload_access
    AuditLog.where(event_type: AuditService::EVENTS[:payload_accessed], created_at: 5.minutes.ago..Time.current)
            .group(:ip_address)
            .having('COUNT(DISTINCT payload_id) > ?', 30)
            .pluck(:ip_address)
  end

  def check_system_health
    # Placeholder for system health checks
  end

  def cleanup_old_tracking_data
    # Placeholder for cleanup tasks
  end
end
