class AddAuditLogPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :audit_logs, [:event_type, :created_at], name: 'idx_audit_logs_event_time'
    add_index :audit_logs, [:ip_address, :created_at], name: 'idx_audit_logs_ip_time'
    add_index :audit_logs, [:severity, :created_at], name: 'idx_audit_logs_severity_time'

    if connection.adapter_name.downcase.include?('postgresql')
      execute "CREATE INDEX idx_audit_logs_metadata_gin ON audit_logs USING GIN (metadata)"
    end

    add_index :audit_logs, :created_at,
              where: "severity IN ('warning', 'critical')",
              name: 'idx_audit_logs_critical_time'
  end
end
