require 'rails_helper'

RSpec.describe SlackNotificationJob, type: :job do
  let(:webhook_url) { 'https://hooks.slack.com/services/T000/B000/XXXX' }
  let(:message) { 'Hello slack' }

  it 'posts payload to the webhook' do
    uri = URI.parse(webhook_url)
    expect(Net::HTTP).to receive(:post).with(uri, { text: message }.to_json, "Content-Type" => "application/json")

    described_class.new.perform(webhook_url: webhook_url, message: message)
  end

  it 'logs errors without raising' do
    allow(Net::HTTP).to receive(:post).and_raise(StandardError.new('fail'))
    expect(Rails.logger).to receive(:error).with(/Slack notification failed: fail/)

    expect {
      described_class.new.perform(webhook_url: webhook_url, message: message)
    }.not_to raise_error
  end
end
