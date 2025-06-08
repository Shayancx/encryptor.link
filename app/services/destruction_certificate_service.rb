class DestructionCertificateService
  class CertificateError < StandardError; end
  class VerificationError < StandardError; end

  def self.generate_for_payload(payload, reason = "viewed")
    raise CertificateError, "Payload cannot be nil" if payload.nil?
    raise CertificateError, "Invalid destruction reason" unless valid_reason?(reason)

    ActiveRecord::Base.transaction do
      certificate = DestructionCertificate.new(
        encrypted_payload: payload,
        destruction_reason: reason,
        payload_metadata: build_payload_metadata(payload)
      )

      unless certificate.save
        raise CertificateError, "Failed to create certificate: #{certificate.errors.full_messages.join(', ')}"
      end

      certificate
    end
  rescue => e
    Rails.logger.error "Certificate generation failed: #{e.message}"
    raise CertificateError, "Failed to generate destruction certificate"
  end

  def self.verify_certificate(certificate_hash)
    raise VerificationError, "Certificate hash cannot be blank" if certificate_hash.blank?

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
    raise CertificateError, "Certificate cannot be nil" if certificate.nil?

    data = JSON.parse(certificate.certificate_data)

    <<~CERTIFICATE
      ====================================================
      CERTIFICATE OF DESTRUCTION
      ====================================================

      Certificate ID: #{certificate.certificate_id}
      Issued: #{certificate.created_at.strftime('%B %d, %Y at %I:%M %p UTC')}

      This certifies that encrypted payload:
      ID: #{data['payload_id']}

      Was permanently destroyed on:
      #{data['destroyed_at']}

      Reason: #{certificate.destruction_reason&.humanize}

      Payload Checksum: #{data['payload_checksum']}
      Certificate Version: #{data['version']}

      Certificate Hash: #{certificate.certificate_hash}

      ====================================================
      IMPORTANT NOTICE:
      This certificate provides cryptographic proof that the
      referenced encrypted payload has been permanently destroyed
      and cannot be recovered.

      Verify this certificate at:
      #{Rails.application.routes.url_helpers.verify_certificate_url(certificate.certificate_hash, host: 'encryptor.link')}
      ====================================================
    CERTIFICATE
  end

  class << self
    private

    def valid_reason?(reason)
      %w[viewed final_view burn_after_reading manual expired cleanup test].include?(reason)
    end

    def build_payload_metadata(payload)
      {
        created_at: payload.created_at.iso8601,
        original_expiry: payload.expires_at.iso8601,
        was_password_protected: payload.password_protected,
        file_count: payload.encrypted_files.count,
        total_size: calculate_total_size(payload),
        burn_after_reading: payload.burn_after_reading
      }
    end

    def calculate_total_size(payload)
      size = payload.ciphertext.bytesize
      size += payload.encrypted_files.sum(:file_size) if payload.encrypted_files.any?
      size
    end
  end
end
