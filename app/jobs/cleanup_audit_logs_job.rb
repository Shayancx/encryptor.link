class CleanupAuditLogsJob < ApplicationJob
  queue_as :default

  def perform
    deleted_count = AuditLog.where('created_at < ?', 90.days.ago).delete_all
    AuditService.log(
      event_type: AuditService::EVENTS[:system_cleanup],
      metadata: {
        deleted_audit_logs: deleted_count,
        cleanup_type: 'audit_logs'
      }
    )
  end
end
