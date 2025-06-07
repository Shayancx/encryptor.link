require 'rails_helper'

RSpec.describe "Certificates API", type: :request do
  describe "GET /certificates/:id" do
    it "returns certificate text file" do
      payload = create(:encrypted_payload)
      certificate = DestructionCertificateService.generate_for_payload(payload, "test")

      get "/certificates/#{certificate.certificate_id}.txt"

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/plain")
      expect(response.body).to include("CERTIFICATE OF DESTRUCTION")
      expect(response.body).to include(certificate.certificate_id)
      expect(response.body).to include("Certificate Version: 1.0")
    end

    it "returns 404 for non-existent certificate" do
      get "/certificates/nonexistent.txt"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /certificates/verify/:hash" do
    it "verifies valid certificate" do
      payload = create(:encrypted_payload)
      certificate = DestructionCertificateService.generate_for_payload(payload, "test")

      get "/certificates/verify/#{certificate.certificate_hash}"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['valid']).to be true
      expect(json['certificate']['certificate_id']).to eq(certificate.certificate_id)
    end

    it "returns invalid for tampered certificate" do
      payload = create(:encrypted_payload)
      certificate = DestructionCertificateService.generate_for_payload(payload, "test")

      certificate.update_column(:certificate_data, '{"tampered": true}')

      get "/certificates/verify/#{certificate.certificate_hash}"

      json = JSON.parse(response.body)
      expect(json['valid']).to be false
    end

    it "returns 422 for non-existent hash" do
      get "/certificates/verify/nonexistent"

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['valid']).to be false
    end
  end
end
