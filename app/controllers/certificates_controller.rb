class CertificatesController < ApplicationController
  def show
    certificate = DestructionCertificate.find_by!(certificate_id: params[:id])

    respond_to do |format|
      format.text do
        send_data DestructionCertificateService.generate_certificate_file(certificate),
                  filename: "destruction-certificate-#{certificate.certificate_id}.txt",
                  type: "text/plain"
      end
      format.json { render json: certificate_json(certificate) }
    end
  end

  def verify
    result = DestructionCertificateService.verify_certificate(params[:hash])

    if result && result[:valid]
      render json: {
        valid: true,
        message: "This destruction certificate is valid and authentic.",
        certificate: certificate_json(result[:certificate]),
        verified_at: result[:verification_timestamp]
      }
    else
      render json: {
        valid: false,
        message: "Invalid or tampered certificate."
      }, status: :unprocessable_entity
    end
  end

  private

  def certificate_json(certificate)
    data = JSON.parse(certificate.certificate_data)
    {
      certificate_id: certificate.certificate_id,
      destroyed_at: data["destroyed_at"],
      reason: certificate.destruction_reason,
      metadata: certificate.payload_metadata,
      hash: certificate.certificate_hash
    }
  end
end
