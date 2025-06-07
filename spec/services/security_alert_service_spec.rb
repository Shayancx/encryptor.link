require 'rails_helper'

RSpec.describe SecurityAlertService do
  describe '.check_and_alert' do
    it 'sends alert when failed logins exceed threshold' do
      ip = '5.5.5.5'
      create_list(:audit_log, 10, event_type: AuditService::EVENTS[:admin_login_failed], ip_address: ip, created_at: 10.minutes.ago)

      allow(AdminAlertMailer).to receive_message_chain(:security_alert, :deliver_now)
      allow(SlackNotificationJob).to receive(:perform_later)
      expect(AuditService).to receive(:log).with(
        hash_including(event_type: AuditService::EVENTS[:security_alert_sent])
      ).and_call_original

      SecurityAlertService.check_and_alert(AuditService::EVENTS[:admin_login_failed], ip)
    end
  end
end
