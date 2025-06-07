class DestructionCertificateService
  def self.generate_for_payload(payload, reason = "viewed")
    certificate = DestructionCertificate.new(
      encrypted_payload: payload,
      destruction_reason: reason,
      payload_metadata: {
        created_at: payload.created_at.iso8601,
        original_expiry: payload.expires_at.iso8601,
        was_password_protected: payload.password_protected,
        file_count: payload.encrypted_files.count,
        total_size: calculate_total_size(payload)
      }
    )

    certificate.save!
    certificate
  end

  def self.verify_certificate(certificate_hash)
    certificate = DestructionCertificate.find_by(certificate_hash: certificate_hash)
    return nil unless certificate

    expected_hash = Digest::SHA256.hexdigest(certificate.certificate_data)

    {
      valid: expected_hash == certificate.certificate_hash,
      certificate: certificate,
      verification_timestamp: Time.current.iso8601
    }
  end

  def self.generate_certificate_file(certificate)
    <<~CERTIFICATE
      ====================================================
      CERTIFICATE OF DESTRUCTION
      ====================================================

      Certificate ID: #{certificate.certificate_id}
      Issued: #{certificate.created_at.strftime('%B %d, %Y at %I:%M %p UTC')}

      This certifies that encrypted payload:
      ID: #{JSON.parse(certificate.certificate_data)['payload_id']}

      Was permanently destroyed on:
      #{JSON.parse(certificate.certificate_data)['destroyed_at']}

      Reason: #{certificate.destruction_reason&.humanize}

      Payload Checksum: #{JSON.parse(certificate.certificate_data)['payload_checksum']}
      Server Signature: #{JSON.parse(certificate.certificate_data)['server_signature']}

      Certificate Hash: #{certificate.certificate_hash}

      ====================================================
      Verify this certificate at:
      #{Rails.application.routes.url_helpers.verify_certificate_url(certificate.certificate_hash)}
      ====================================================
    CERTIFICATE
  end

  class << self
    private

    def calculate_total_size(payload)
      size = payload.ciphertext.bytesize
      size += payload.encrypted_files.sum(:file_size) if payload.encrypted_files.any?
      size
    end
  end
end
