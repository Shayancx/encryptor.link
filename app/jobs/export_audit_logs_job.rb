require "csv"

class ExportAuditLogsJob < ApplicationJob
  queue_as :default

  def perform(admin_id, filters = {}, ip)
    admin = AdminUser.find_by(id: admin_id)
    logs = AuditLog.where(filters.except("page", "per_page"))
    csv_data = CSV.generate(headers: true) do |csv|
      csv << %w[id event_type created_at ip_address endpoint]
      logs.find_each do |log|
        csv << [ log.id, log.event_type, log.created_at, log.ip_address, log.endpoint ]
      end
    end
    AdminAlertMailer.security_alert(
      severity: "info",
      title: "Audit Log Export",
      details: "Your audit log export is attached.",
      ip_address: ip
    ).attachments["audit_logs.csv"] = { mime_type: "text/csv", content: csv_data }
  end
end
