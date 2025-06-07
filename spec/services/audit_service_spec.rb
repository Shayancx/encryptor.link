require 'rails_helper'

RSpec.describe AuditService do
  describe '.log' do
    it 'creates an audit log with metadata' do
      request = instance_double(ActionDispatch::Request,
                                path: '/test',
                                ip: '1.2.3.4',
                                user_agent: 'RSpec',
                                content_length: 10)

      expect {
        described_class.log(event_type: AuditService::EVENTS[:payload_created],
                             request: request,
                             metadata: { foo: 'bar' })
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.order(created_at: :desc).first
      expect(log.event_type).to eq(AuditService::EVENTS[:payload_created])
      expect(log.ip_address).to eq('1.2.3.4')
      expect(log.metadata['foo']).to eq('bar')
    end

    it 'flags suspicious activity and records threat indicators' do
      ip = '1.1.1.1'
      create_list(:audit_log, 6,
                  event_type: AuditService::EVENTS[:unauthorized_audit_access],
                  ip_address: ip,
                  created_at: 10.minutes.ago)
      create_list(:audit_log, 101,
                  event_type: AuditService::EVENTS[:payload_accessed],
                  ip_address: ip,
                  created_at: 30.seconds.ago)
      Array.new(25) do
        create(
          :audit_log,
          event_type: AuditService::EVENTS[:payload_accessed],
          ip_address: ip,
          payload_id: SecureRandom.uuid,
          created_at: 2.minutes.ago
        )
      end

      request = instance_double(ActionDispatch::Request,
                                path: '/admin',
                                ip: ip,
                                user_agent: 'Bot',
                                content_length: 123)

      described_class.log(event_type: AuditService::EVENTS[:unauthorized_audit_access],
                          request: request)

      log = AuditLog.order(created_at: :desc).first
      expect(log.event_type).to eq(AuditService::EVENTS[:suspicious_activity])
      expect(log.severity).to eq('critical')
      expect(log.metadata['original_event']).to eq(AuditService::EVENTS[:unauthorized_audit_access])
      indicators = log.metadata['threat_indicators']
      expect(indicators).to include('rapid_requests', 'invalid_user_agent', 'payload_enumeration')
    end
  end
end
