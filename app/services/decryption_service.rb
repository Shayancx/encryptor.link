# frozen_string_literal: true

# Service object for handling decryption-related business logic
class DecryptionService
  class DecryptionError < StandardError; end

  def initialize(payload_id)
    @payload_id = payload_id
  end

  def retrieve_data
    payload = find_payload
    return nil unless payload
    return nil if payload.expires_at < Time.current

    payload.with_lock do
      return nil if payload.remaining_views <= 0

      # For burn after reading, always delete immediately
      if payload.burn_after_reading
        certificate = DestructionCertificateService.generate_for_payload(payload, "burn_after_reading")
        data = build_response_data(payload)
        data[:destruction_certificate_id] = certificate.certificate_id
        payload.destroy
        return data
      end

      payload.decrement!(:remaining_views)
      should_delete = payload.remaining_views <= 0

      data = build_response_data(payload)
      if should_delete
        certificate = DestructionCertificateService.generate_for_payload(payload, "final_view")
        data[:destruction_certificate_id] = certificate.certificate_id
        schedule_deletion(payload)
      end

      AuditService.log(
        event_type: AuditService::EVENTS[:payload_accessed],
        payload_id: @payload_id,
        metadata: {
          remaining_views: payload.remaining_views,
          burn_after_reading: payload.burn_after_reading
        }
      )

      data
    end
  end

  def payload_info
    payload = find_payload
    return { exists: false } unless payload

    {
      exists: true,
      password_protected: payload.password_protected,
      expired: payload.expires_at < Time.current,
      burn_after_reading: payload.burn_after_reading
    }
  end

  private

  def find_payload
    EncryptedPayload.find_by(id: @payload_id)
  end

  def build_response_data(payload)
    {
      ciphertext: encode_base64(payload.ciphertext),
      nonce: encode_base64(payload.nonce),
      password_protected: payload.password_protected,
      password_salt: payload.password_salt.present? ? encode_base64(payload.password_salt) : nil,
      files: payload.encrypted_files.map { |file| serialize_file(file) }
    }
  end

  def encode_base64(data)
    Base64.strict_encode64(data || "")
  end

  def serialize_file(file)
    {
      id: file.id,
      data: file.file_data,
      name: file.file_name,
      type: file.file_type,
      size: file.file_size
    }
  end

  def schedule_deletion(payload)
    if Rails.env.test?
      payload.destroy
    else
      CleanupPayloadJob.perform_later(payload.id)
    end
  end
end
