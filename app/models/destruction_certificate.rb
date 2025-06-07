require "digest"

class DestructionCertificate < ApplicationRecord
  belongs_to :encrypted_payload, optional: true

  before_create :generate_certificate_data

  private

  def generate_certificate_data
    self.certificate_id = SecureRandom.hex(32)

    payload_data = {
      certificate_id: certificate_id,
      payload_id: encrypted_payload.id,
      payload_checksum: encrypted_payload.ciphertext_checksum,
      destroyed_at: Time.current.iso8601,
      destruction_reason: destruction_reason,
      server_signature: generate_server_signature
    }

    self.certificate_data = payload_data.to_json
    self.certificate_hash = Digest::SHA256.hexdigest(certificate_data)
  end

  def generate_server_signature
    data_to_sign = "#{encrypted_payload.id}:#{encrypted_payload.ciphertext_checksum}:#{Time.current.to_i}"
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.credentials.secret_key_base, data_to_sign)
  end
end
