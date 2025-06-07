require 'rails_helper'

RSpec.describe CleanupAuditLogsJob, type: :job do
  describe '#perform' do
    it 'deletes logs older than 90 days and logs the cleanup' do
      old_logs = create_list(:audit_log, 2, created_at: 91.days.ago)
      recent_log = create(:audit_log)

      expect(AuditService).to receive(:log).with(
        event_type: AuditService::EVENTS[:system_cleanup],
        metadata: hash_including(
          deleted_audit_logs: 2,
          cleanup_type: 'audit_logs'
        )
      )

      described_class.new.perform

      expect(AuditLog.where(id: old_logs.map(&:id))).to be_empty
      expect(AuditLog.where(id: recent_log.id)).to exist
    end
  end
end
