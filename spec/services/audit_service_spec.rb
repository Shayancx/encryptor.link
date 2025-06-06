require 'rails_helper'

RSpec.describe AuditService do
  it 'creates an audit log' do
    expect {
      described_class.log(event_type: AuditService::EVENTS[:payload_created])
    }.to change(AuditLog, :count).by(1)
  end
end
