require 'rails_helper'

RSpec.describe "Encryption Security", type: :request do
  describe 'CSRF protection' do
    it 'rejects POST without CSRF token when protection is enabled' do
      # Temporarily enable CSRF protection for this test
      original_setting = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true

      begin
        post '/encrypt', params: {
          ciphertext: Base64.strict_encode64('test'),
          nonce: Base64.strict_encode64('testnonce123'),
          ttl: 3600,
          views: 1
        }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      ensure
        ActionController::Base.allow_forgery_protection = original_setting
      end
    end

    it 'accepts POST with valid CSRF token' do
      original_setting = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      begin
        get '/encrypt'
        token = Nokogiri::HTML(response.body).at('meta[name="csrf-token"]')['content']

        post '/encrypt', params: {
          ciphertext: Base64.strict_encode64('test'),
          nonce: Base64.strict_encode64('testnonce123'),
          ttl: 3600,
          views: 1
        }, as: :json, headers: {
          'X-CSRF-Token' => token
        }

        expect(response).to have_http_status(:success)
      ensure
        ActionController::Base.allow_forgery_protection = original_setting
      end
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

        expect(response).to have_http_status(:unprocessable_entity)
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

      # Times should be reasonably close to avoid timing attacks
      expect((valid_time - invalid_time).abs).to be < 0.1
    end
  end

  describe 'ID enumeration prevention' do
    it 'uses UUIDs to prevent enumeration' do
      # Create more payloads to reduce chance of false positive
      # With 10 UUIDs, chance of random sorted order is 1/10! ≈ 0.0000028%
      payloads = create_list(:encrypted_payload, 10)
      ids = payloads.map(&:id)

      # IDs should be valid UUIDs
      uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      ids.each do |id|
        expect(id).to match(uuid_regex)
      end

      # Should not be sequential/predictable
      # Test multiple aspects of randomness
      sorted_ids = ids.sort

      # Primary test: IDs should not be in sorted order
      expect(sorted_ids).not_to eq(ids), "UUIDs appear to be generated in sorted order"

      # Secondary test: Check if first characters show randomness
      first_chars = ids.map { |id| id[0] }
      expect(first_chars.uniq.size).to be > 3, "UUID first characters not diverse enough"

      # Tertiary test: Ensure all UUIDs are unique
      expect(ids.uniq.size).to eq(ids.size), "Duplicate UUIDs found"
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
