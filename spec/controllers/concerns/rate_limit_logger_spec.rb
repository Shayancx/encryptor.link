require 'rails_helper'

RSpec.describe RateLimitLogger do
  it 'logs warning when throttle event occurs' do
    req = ActionDispatch::Request.new(Rack::MockRequest.env_for('/secret'))
    req.env['rack.attack.matched'] = 'req/ip'
    req.env['rack.attack.match_type'] = :throttle

    expect(Rails.logger).to receive(:warn).with(/Rate limit exceeded for #{req.ip} on \/secret/)
    ActiveSupport::Notifications.instrument('rack.attack', request: req)
  end

  it 'does not log for non-throttle events' do
    req = ActionDispatch::Request.new(Rack::MockRequest.env_for('/open'))
    req.env['rack.attack.matched'] = nil
    req.env['rack.attack.match_type'] = :allow2

    expect(Rails.logger).not_to receive(:warn)
    ActiveSupport::Notifications.instrument('rack.attack', request: req)
  end
end
