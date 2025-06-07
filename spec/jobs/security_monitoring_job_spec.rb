require 'rails_helper'

RSpec.describe SecurityMonitoringJob, type: :job do
  describe '#perform' do
    it 'sends alerts for unusual ip and mass payload access' do
      ip = '1.2.3.4'
      # create >100 logs in last hour
      create_list(:audit_log, 101, ip_address: ip, created_at: 30.minutes.ago)
      # create >30 distinct payload accesses in last 5 minutes
      31.times do
        create(:audit_log, event_type: AuditService::EVENTS[:payload_accessed], ip_address: ip, payload_id: SecureRandom.uuid, created_at: 2.minutes.ago)
      end

      SecurityAlertService.singleton_class.class_eval { public :send_alert }
      expect(SecurityAlertService).to receive(:send_alert).with(hash_including(severity: 'medium', title: 'Unusual IP Activity', ip_address: ip))
      expect(SecurityAlertService).to receive(:send_alert).with(hash_including(severity: 'high', title: 'Payload Enumeration', ip_address: ip))

      described_class.new.perform
    end
  end
end
