require 'rails_helper'

RSpec.describe "Encryption Security", type: :request do
  describe 'CSRF protection' do
    it 'rejects POST without CSRF token' do
      ActionController::Base.allow_forgery_protection = true

      post '/encrypt', params: { nonce: 'test' }
      expect(response).to have_http_status(:unprocessable_entity)

      ActionController::Base.allow_forgery_protection = false
    end
  end

  describe 'Input validation' do
    it 'validates base64 encoding' do
      post '/encrypt', params: {
        ciphertext: 'not-base64!@#',
        nonce: Base64.strict_encode64('nonce'),
        ttl: 3600,
        views: 1
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'prevents payload size attacks' do
      huge_payload = 'a' * 100.megabytes

      post '/encrypt', params: {
        ciphertext: Base64.strict_encode64(huge_payload),
        nonce: Base64.strict_encode64('nonce'),
        ttl: 3600,
        views: 1
      }, as: :json

      # Should fail due to request size limits
      expect(response).not_to have_http_status(:success)
    end
  end

  describe 'Timing attack prevention' do
    it 'returns consistent timing for valid/invalid payloads' do
      valid_id = create(:encrypted_payload).id
      invalid_id = SecureRandom.uuid

      # Measure timing for valid payload
      start_time = Time.now
      get "/#{valid_id}/data"
      valid_time = Time.now - start_time

      # Measure timing for invalid payload
      start_time = Time.now
      get "/#{invalid_id}/data"
      invalid_time = Time.now - start_time

      # Times should be similar (within 50ms)
      expect((valid_time - invalid_time).abs).to be < 0.05
    end
  end

  describe 'ID enumeration prevention' do
    it 'uses UUIDs to prevent enumeration' do
      payloads = create_list(:encrypted_payload, 3)
      ids = payloads.map(&:id)

      # IDs should be UUIDs
      ids.each do |id|
        expect(id).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
      end

      # Should not be sequential
      expect(ids.sort).not_to eq(ids)
    end
  end

  describe 'Header security' do
    it 'includes security headers' do
      get root_path

      expect(response.headers['X-Frame-Options']).to eq('DENY')
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
      expect(response.headers['Content-Security-Policy']).to be_present
    end
  end
end
