# frozen_string_literal: true

# Service object for handling encryption-related business logic
class EncryptionService
  class EncryptionError < StandardError; end

  MAX_TTL = 7.days.to_i
  MAX_VIEWS = 5
  MAX_FILE_SIZE = 1000.megabytes
  MAX_PAYLOAD_SIZE = 50.megabytes

  def initialize(params)
    @params = params
  end

  def create_payload
    validate_params!

    ActiveRecord::Base.transaction do
      payload = build_payload
      payload.save!
      attach_files(payload) if @params[:files].present?
      payload
    end
  rescue ActiveRecord::RecordInvalid => e
    raise EncryptionError, e.record.errors.full_messages.join(", ")
  end

  private

  def validate_params!
    raise EncryptionError, "Nonce is required" unless @params[:nonce].present?
    raise EncryptionError, "TTL and views are required" unless @params[:ttl].present? && @params[:views].present?

    if @params[:ciphertext].present?
      decoded_size = Base64.strict_decode64(@params[:ciphertext]).bytesize rescue (raise EncryptionError, "Invalid base64 encoding")
      raise EncryptionError, "Payload too large" if decoded_size > MAX_PAYLOAD_SIZE
    end

    views = @params[:views].to_i
    raise EncryptionError, "Views must be between 1 and #{MAX_VIEWS}" unless views.between?(1, MAX_VIEWS)
  end

  def build_payload
    EncryptedPayload.new(
      ciphertext: decode_base64(@params[:ciphertext]) || "",
      nonce: decode_base64(@params[:nonce]),
      expires_at: calculate_expiry,
      burn_after_reading: ActiveModel::Type::Boolean.new.cast(@params[:burn_after_reading]) || false,
      remaining_views: burn_after_reading? ? 1 : @params[:views].to_i,
      password_protected: ActiveModel::Type::Boolean.new.cast(@params[:password_protected]) || false,
      password_salt: decode_base64(@params[:password_salt])
    )
  end

  def burn_after_reading?
    ActiveModel::Type::Boolean.new.cast(@params[:burn_after_reading])
  end

  def decode_base64(data)
    return nil unless data.present?
    Base64.strict_decode64(data)
  rescue ArgumentError
    raise EncryptionError, "Invalid base64 encoding"
  end

  def calculate_expiry
    ttl = [ @params[:ttl].to_i, MAX_TTL ].min
    Time.current + ttl.seconds
  end

  def attach_files(payload)
    @params[:files].each_with_index do |file, index|
      validate_file!(file, index)
      payload.encrypted_files.create!(
        file_data: file[:data],
        file_name: file[:name],
        file_type: file[:type],
        file_size: file[:size].to_i
      )
    end
  end

  def validate_file!(file, index)
    raise EncryptionError, "File #{index + 1}: data is required" unless file[:data].present?
    raise EncryptionError, "File #{index + 1}: name is required" unless file[:name].present?

    size = file[:size].to_i
    raise EncryptionError, "File #{index + 1}: size exceeds #{MAX_FILE_SIZE / 1.megabyte}MB" if size > MAX_FILE_SIZE
  end
end
