require 'rails_helper'

RSpec.feature "Destruction Certificate Flow", type: :feature do
  scenario "Certificate is generated when message is destroyed", js: true do
    payload = create(:encrypted_payload, remaining_views: 1)

    visit "/#{payload.id}#testkey"
    sleep 1

    certificate = DestructionCertificate.last
    expect(certificate).not_to be_nil
    expect(certificate.encrypted_payload_id).to eq(payload.id)
    expect(certificate.destruction_reason).to eq("final_view")
  end

  scenario "Burn after reading generates immediate certificate", js: true do
    payload = create(:encrypted_payload, burn_after_reading: true)

    visit "/#{payload.id}#testkey"
    sleep 1

    certificate = DestructionCertificate.last
    expect(certificate).not_to be_nil
    expect(certificate.destruction_reason).to eq("burn_after_reading")
  end

  scenario "Certificate can be downloaded" do
    payload = create(:encrypted_payload)
    certificate = DestructionCertificateService.generate_for_payload(payload, "manual")

    visit "/certificates/#{certificate.certificate_id}.txt"

    expect(page.response_headers['Content-Type']).to include('text/plain')
    expect(page.body).to include("CERTIFICATE OF DESTRUCTION")
    expect(page.body).to include(certificate.certificate_id)
  end

  scenario "Certificate can be verified" do
    payload = create(:encrypted_payload)
    certificate = DestructionCertificateService.generate_for_payload(payload, "test")

    visit "/certificates/verify/#{certificate.certificate_hash}"

    json = JSON.parse(page.body)
    expect(json['valid']).to be true
    expect(json['certificate']['certificate_id']).to eq(certificate.certificate_id)
  end
end
