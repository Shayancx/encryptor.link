require 'rails_helper'

RSpec.describe "Rate Limiting", type: :request do
  before do
    # Enable rate limiting for tests
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.enabled = false
  end

  describe 'encryption endpoint' do
    let(:valid_params) do
      {
        ciphertext: Base64.strict_encode64('data'),
        nonce: Base64.strict_encode64(SecureRandom.random_bytes(12)),
        ttl: 3600,
        views: 1
      }
    end

    it 'allows 10 requests per minute' do
      10.times do
        post '/encrypt', params: valid_params, headers: { 'REMOTE_ADDR': '1.2.3.4' }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      post '/encrypt', params: valid_params, headers: { 'REMOTE_ADDR': '1.2.3.4' }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'decryption data endpoint' do
    let(:payload) { create(:encrypted_payload, remaining_views: 50) }

    it 'allows 30 requests per minute' do
      30.times do
        get "/#{payload.id}/data", headers: { 'REMOTE_ADDR': '1.2.3.5' }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      get "/#{payload.id}/data", headers: { 'REMOTE_ADDR': '1.2.3.5' }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'payload enumeration protection' do
    it 'blocks IPs accessing too many distinct payloads' do
      # Create multiple payloads
      payloads = create_list(:encrypted_payload, 45, remaining_views: 1)

      # Access 40 different payloads - should pass
      payloads[0..39].each do |payload|
        get "/#{payload.id}/data", headers: { 'REMOTE_ADDR': '1.2.3.6' }
      end

      # 41st should be blocked
      get "/#{payloads[40].id}/data", headers: { 'REMOTE_ADDR': '1.2.3.6' }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'response headers' do
    it 'includes Retry-After header when rate limited' do
      11.times do
        post '/encrypt', params: { nonce: 'test', ttl: 1, views: 1 },
             headers: { 'REMOTE_ADDR': '1.2.3.7' }
      end

      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['Retry-After']).to be_present
    end
  end
end
