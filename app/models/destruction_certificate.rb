require "digest"
require "openssl"

class DestructionCertificate < ApplicationRecord
  belongs_to :encrypted_payload, optional: true

  before_validation :generate_certificate_data, on: :create
  validates :certificate_id, :certificate_hash, :certificate_data, presence: true, if: -> { encrypted_payload.present? }

  class CertificateGenerationError < StandardError; end

  private

  def generate_certificate_data
    return if encrypted_payload.nil?
    self.certificate_id = SecureRandom.hex(32)

    payload_data = build_certificate_payload
    self.certificate_data = payload_data.to_json
    self.certificate_hash = calculate_certificate_hash(certificate_data)
  rescue => e
    Rails.logger.error "Failed to generate destruction certificate: #{e.message}"
    raise CertificateGenerationError, "Failed to generate destruction certificate"
  end

  def build_certificate_payload
    {
      certificate_id: certificate_id,
      payload_id: encrypted_payload.id,
      payload_checksum: Digest::SHA256.hexdigest(encrypted_payload.ciphertext),
      destroyed_at: Time.current.iso8601,
      destruction_reason: destruction_reason,
      version: "1.0"
    }
  end

  def calculate_certificate_hash(data)
    # Use SHA256 for certificate integrity
    Digest::SHA256.hexdigest(data)
  end
end
