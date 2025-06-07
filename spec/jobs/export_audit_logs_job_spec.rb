require 'rails_helper'

RSpec.describe ExportAuditLogsJob, type: :job do
  describe '#perform' do
    it 'generates CSV and attaches it to the alert email' do
      admin = create(:admin_user)
      log = create(:audit_log, event_type: 'test_event')
      mail = Mail::Message.new
      allow(AdminAlertMailer).to receive(:security_alert).and_return(mail)

      described_class.new.perform(admin.id, {}, '127.0.0.1')

      attachment = mail.attachments['audit_logs.csv']
      expect(attachment).to be_present
      csv = CSV.parse(attachment.body.decoded, headers: true)
      expect(csv.first['event_type']).to eq(log.event_type)
    end
  end
end
