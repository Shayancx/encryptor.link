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
      payload_checksum: encrypted_payload.ciphertext_checksum,
      destroyed_at: Time.current.iso8601,
      destruction_reason: destruction_reason,
      server_signature: generate_server_signature,
      version: "1.0"
    }
  end

  def generate_server_signature
    signing_key = fetch_signing_key
    data_to_sign = "#{encrypted_payload.id}:#{encrypted_payload.ciphertext_checksum}:#{Time.current.to_i}"

    OpenSSL::HMAC.hexdigest("SHA256", signing_key, data_to_sign)
  end

  def fetch_signing_key
    key = Rails.application.credentials.secret_key_base
    key ||= Rails.application.secrets.secret_key_base if Rails.application.respond_to?(:secrets)
    key ||= Rails.configuration.secret_key_base

    if key.blank?
      raise CertificateGenerationError, "No signing key available for destruction certificates"
    end

    # Ensure key is at least 64 characters for security
    Rails.logger.warn "Signing key is shorter than recommended 64 characters" if key.length < 64

    key
  end

  def calculate_certificate_hash(data)
    # Use SHA256 for certificate integrity
    Digest::SHA256.hexdigest(data)
  end
end
