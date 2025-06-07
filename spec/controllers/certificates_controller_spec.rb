require 'rails_helper'

RSpec.describe CertificatesController, type: :controller do
  describe 'GET #show' do
    it 'returns certificate text' do
      payload = create(:encrypted_payload)
      certificate = DestructionCertificateService.generate_for_payload(payload, 'viewed')

      get :show, params: { id: certificate.certificate_id }, format: :text
      expect(response).to have_http_status(:success)
      expect(response.body).to include('CERTIFICATE OF DESTRUCTION')
    end
  end

  describe 'GET #verify' do
    it 'verifies a valid certificate' do
      payload = create(:encrypted_payload)
      certificate = DestructionCertificateService.generate_for_payload(payload, 'viewed')

      get :verify, params: { hash: certificate.certificate_hash }, format: :json
      json = JSON.parse(response.body)
      expect(json['valid']).to be true
      expect(json['certificate']['certificate_id']).to eq(certificate.certificate_id)
    end

    it 'returns invalid for unknown hash' do
      get :verify, params: { hash: 'bad' }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['valid']).to be false
    end
  end
end
