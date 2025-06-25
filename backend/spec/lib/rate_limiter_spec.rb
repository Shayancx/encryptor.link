# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RateLimiter do
  let(:db) { TEST_DB }
  let(:ip) { '192.168.1.1' }
  let(:endpoint) { '/api/upload' }

  describe '.check_rate_limit' do
    context 'when under the limit' do
      it 'allows the request' do
        result = RateLimiter.check_rate_limit(db, ip, endpoint)

        expect(result[:allowed]).to be true
        expect(result[:retry_after]).to be_nil
      end

      it 'logs the access' do
        expect do
          RateLimiter.check_rate_limit(db, ip, endpoint)
        end.to change { db[:access_logs].count }.by(1)

        log = db[:access_logs].order(:id).last
        expect(log[:ip_address]).to eq(ip)
        expect(log[:endpoint]).to eq(endpoint)
      end
    end

    context 'when exceeding the limit' do
      before do
        # Max out the rate limit
        limit = RateLimiter::MAX_REQUESTS[endpoint]
        limit.times do
          RateLimiter.check_rate_limit(db, ip, endpoint)
        end
      end

      it 'blocks the request' do
        result = RateLimiter.check_rate_limit(db, ip, endpoint)

        expect(result[:allowed]).to be false
        expect(result[:retry_after]).to eq(RateLimiter::WINDOW_SIZE)
      end

      it 'does not log blocked requests' do
        initial_count = db[:access_logs].count

        RateLimiter.check_rate_limit(db, ip, endpoint)

        expect(db[:access_logs].count).to eq(initial_count)
      end
    end

    context 'with different endpoints' do
      it 'tracks limits separately' do
        # Max out upload endpoint
        10.times { RateLimiter.check_rate_limit(db, ip, '/api/upload') }

        # Download endpoint should still work
        result = RateLimiter.check_rate_limit(db, ip, '/api/download')
        expect(result[:allowed]).to be true
      end

      it 'uses default limit for unknown endpoints' do
        unknown_endpoint = '/api/unknown'
        default_limit = RateLimiter::MAX_REQUESTS['default']

        default_limit.times do
          result = RateLimiter.check_rate_limit(db, ip, unknown_endpoint)
          expect(result[:allowed]).to be true
        end

        result = RateLimiter.check_rate_limit(db, ip, unknown_endpoint)
        expect(result[:allowed]).to be false
      end
    end

    context 'with different IPs' do
      it 'tracks limits separately' do
        # Max out first IP
        10.times { RateLimiter.check_rate_limit(db, '1.1.1.1', endpoint) }

        # Second IP should work
        result = RateLimiter.check_rate_limit(db, '2.2.2.2', endpoint)
        expect(result[:allowed]).to be true
      end
    end

    context 'after window expires' do
      it 'allows requests again' do
        # Max out limit
        10.times { RateLimiter.check_rate_limit(db, ip, endpoint) }

        # Time travel past window
        Timecop.travel(Time.now + RateLimiter::WINDOW_SIZE + 1) do
          result = RateLimiter.check_rate_limit(db, ip, endpoint)
          expect(result[:allowed]).to be true
        end
      end
    end
  end

  describe '.cleanup_old_logs' do
    before do
      # Create old logs
      db[:access_logs].insert(
        ip_address: '1.1.1.1',
        endpoint: '/api/upload',
        accessed_at: Time.now - 7200 # 2 hours old
      )

      # Create recent logs
      db[:access_logs].insert(
        ip_address: '2.2.2.2',
        endpoint: '/api/download',
        accessed_at: Time.now - 1800 # 30 minutes old
      )
    end

    it 'removes logs older than 1 hour' do
      initial_count = db[:access_logs].count

      RateLimiter.cleanup_old_logs(db)

      expect(db[:access_logs].count).to be < initial_count

      # Check that old log is gone
      old_logs = db[:access_logs].where(ip_address: '1.1.1.1').count
      expect(old_logs).to eq(0)

      # Check that recent log remains
      recent_logs = db[:access_logs].where(ip_address: '2.2.2.2').count
      expect(recent_logs).to eq(1)
    end

    it 'handles empty database gracefully' do
      db[:access_logs].delete

      expect do
        RateLimiter.cleanup_old_logs(db)
      end.not_to raise_error
    end
  end
end
