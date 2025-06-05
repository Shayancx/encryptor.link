require 'rails_helper'

RSpec.describe CleanupPayloadJob, type: :job do
  it 'destroys payload with no views left' do
    payload = create(:encrypted_payload, remaining_views: 0)
    expect {
      described_class.new.perform(payload.id)
    }.to change(EncryptedPayload, :count).by(-1)
  end

  it 'skips payloads that still have views' do
    payload = create(:encrypted_payload, remaining_views: 1)
    expect(Rails.logger).not_to receive(:info)
    described_class.new.perform(payload.id)
    expect(EncryptedPayload.exists?(payload.id)).to be true
  end

  it 'logs errors during deletion' do
    payload = create(:encrypted_payload, remaining_views: 0)
    allow_any_instance_of(EncryptedPayload).to receive(:destroy).and_raise('fail')
    expect(Rails.logger).to receive(:error).with(/cleanup_payload/)
    expect { described_class.new.perform(payload.id) }.not_to raise_error
  end
end
