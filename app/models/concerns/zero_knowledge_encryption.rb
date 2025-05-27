module ZeroKnowledgeEncryption
  extend ActiveSupport::Concern

  # Derive encryption key from user password
  def derive_key_from_password(password)
    # Use PBKDF2 to derive a key from the password
    salt = Rails.application.credentials.encryption_salt || "encryptor-link-salt-2025"
    OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 100_000, 32, OpenSSL::Digest::SHA256.new)
  end

  # Encrypt data with derived key
  def encrypt_with_key(data, key)
    return nil if data.blank?

    cipher = OpenSSL::Cipher.new("AES-256-GCM")
    cipher.encrypt
    cipher.key = key

    iv = cipher.random_iv
    cipher.auth_data = ""

    encrypted = cipher.update(data.to_json) + cipher.final
    auth_tag = cipher.auth_tag

    # Return base64 encoded result
    Base64.strict_encode64(iv + auth_tag + encrypted)
  end

  # Decrypt data with derived key
  def decrypt_with_key(encrypted_data, key)
    return nil if encrypted_data.blank?

    decoded = Base64.strict_decode64(encrypted_data)

    cipher = OpenSSL::Cipher.new("AES-256-GCM")
    cipher.decrypt

    iv = decoded[0, 12]
    auth_tag = decoded[12, 16]
    encrypted = decoded[28..-1]

    cipher.key = key
    cipher.iv = iv
    cipher.auth_tag = auth_tag
    cipher.auth_data = ""

    decrypted = cipher.update(encrypted) + cipher.final
    JSON.parse(decrypted)
  rescue StandardError => e
    Rails.logger.error "Decryption failed: #{e.message}"
    nil
  end
end
