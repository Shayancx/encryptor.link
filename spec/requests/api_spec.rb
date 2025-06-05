# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "API Endpoints", type: :request do
  describe "POST /encrypt" do
    let(:valid_params) do
      {
        ciphertext: Base64.strict_encode64('data'),
        nonce: Base64.strict_encode64(SecureRandom.random_bytes(12)),
        ttl: 3600,
        views: 1
      }
    end

    it "creates encrypted payload with valid params" do
      post "/encrypt", params: valid_params, as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['id']).to be_present
    end

    it "returns error with invalid params" do
      post "/encrypt", params: {}, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to be_present
    end

    it "handles large payloads gracefully" do
      large_data = 'x' * 10.megabytes
      params = valid_params.merge(ciphertext: Base64.strict_encode64(large_data))

      post "/encrypt", params: params, as: :json

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /:id/data" do
    let(:payload) { create(:encrypted_payload) }

    it "returns payload data" do
      get "/#{payload.id}/data", as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['ciphertext']).to be_present
    end

    it "returns 410 for expired payload" do
      expired = create(:encrypted_payload, :expired)

      get "/#{expired.id}/data", as: :json

      expect(response).to have_http_status(:gone)
    end
  end

  describe "GET /health" do
    it "returns health status" do
      get "/health"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('healthy')
      expect(json['checks']).to be_present
      expect(json['checks']['database']).to be true
      expect(json['checks']['disk_space']).to be true
    end
  end
end
