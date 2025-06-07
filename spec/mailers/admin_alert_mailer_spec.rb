require 'rails_helper'

RSpec.describe AdminAlertMailer, type: :mailer do
  describe '#security_alert' do
    it 'sets subject and recipient with provided details' do
      view_path = Rails.root.join('tmp/spec_mailer_views', 'admin_alert_mailer')
      FileUtils.mkdir_p(view_path)
      File.write(view_path.join('security_alert.text.erb'), 'Alert: <%= @title %> <%= @details %> <%= @ip_address %>')
      AdminAlertMailer.prepend_view_path(view_path.parent)

      mail = described_class.security_alert(
        severity: 'high',
        title: 'Intrusion Detected',
        details: 'Multiple failures',
        ip_address: '1.1.1.1'
      )

      expect(mail.to).to include(ENV['ADMIN_ALERT_EMAIL'] || 'admin@example.com')
      expect(mail.subject).to eq('Security Alert: Intrusion Detected')
      expect(mail.body.decoded).to include('Multiple failures')
      expect(mail.body.decoded).to include('1.1.1.1')
    end
  end
end
