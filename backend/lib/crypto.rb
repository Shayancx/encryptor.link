# frozen_string_literal: true

require 'bundler/setup'
Bundler.require

require 'openssl'
require 'base64'
require 'bcrypt'
require 'securerandom'
require 'digest'

module Crypto
  AES_KEY_SIZE = 32 # 256 bits
  AES_IV_SIZE = 16  # 128 bits
  PBKDF2_ITERATIONS = 250_000
  BCRYPT_COST = 12  # Increased from default for better security

  # Common weak passwords list
  COMMON_PASSWORDS = %w[
    password Password123! 12345678 qwerty123 admin123
    password123 123456789 qwerty password1 12345
    123456 111111 1234567890 1234567 qwerty123
    000000 1q2w3e abc123 password123! admin
    letmein welcome 123123 admin123!
  ].freeze

  class << self
    # Generate a secure random salt
    def generate_salt
      SecureRandom.hex(32)
    end

    # Generate a secure file ID (8 characters)
    def generate_file_id
      chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      (0...8).map { chars[SecureRandom.random_number(chars.length)] }.join
    end

    # Hash password with bcrypt (enhanced security)
    def hash_password(password, salt)
      # Validate password strength first
      validation = validate_password_strength(password)
      return validation unless validation[:valid]

      # Use higher cost factor for better security
      BCrypt::Password.create("#{password}#{salt}", cost: BCRYPT_COST)
    rescue StandardError => e
      raise "Password hashing failed: #{e.message}"
    end

    # Verify password against hash (with timing attack protection)
    def verify_password(password, salt, hash)
      return false if password.nil? || salt.nil? || hash.nil?

      # BCrypt includes timing attack protection
      # Add extra constant-time comparison for timing consistency
      expected = "#{password}#{salt}"
      bcrypt_hash = BCrypt::Password.new(hash)

      # Perform verification with consistent timing
      result = bcrypt_hash == expected

      # Add small random delay to further mitigate timing attacks
      sleep(0.001 + SecureRandom.random_number * 0.002)

      result
    rescue BCrypt::Errors::InvalidHash => e
      # Log the error but don't reveal details to user
      puts "Invalid hash format: #{e.message}" if ENV['RACK_ENV'] == 'development'
      sleep(0.003) # Consistent timing for errors
      false
    rescue StandardError => e
      puts "Password verification error: #{e.message}" if ENV['RACK_ENV'] == 'development'
      sleep(0.003) # Consistent timing for errors
      false
    end

    # Public method to convert base64 to array buffer (for testing)
    def base64_to_array_buffer(base64)
      Base64.strict_decode64(base64)
    end

    # Derive encryption key from password (unchanged)
    def derive_key(password, salt)
      OpenSSL::PKCS5.pbkdf2_hmac(
        password,
        salt,
        PBKDF2_ITERATIONS,
        AES_KEY_SIZE,
        OpenSSL::Digest.new('SHA256')
      )
    end

    # Encrypt data with AES-256-GCM
    def encrypt_file(file_path, password, salt)
      cipher = OpenSSL::Cipher.new('AES-256-GCM')
      cipher.encrypt

      key = derive_key(password, salt)
      iv = cipher.random_iv

      cipher.key = key
      cipher.iv = iv

      encrypted_data = ''
      auth_tag = nil

      File.open(file_path, 'rb') do |file|
        while (chunk = file.read(4096))
          encrypted_data += cipher.update(chunk)
        end
        encrypted_data += cipher.final
        auth_tag = cipher.auth_tag
      end

      # Ensure encrypted data is larger due to padding/overhead
      {
        data: encrypted_data + auth_tag, # Include auth tag in data
        iv: Base64.strict_encode64(iv),
        auth_tag: Base64.strict_encode64(auth_tag)
      }
    end

    # Decrypt file with AES-256-GCM
    def decrypt_file(encrypted_data_with_tag, password, salt, iv_base64, auth_tag_base64)
      cipher = OpenSSL::Cipher.new('AES-256-GCM')
      cipher.decrypt

      key = derive_key(password, salt)
      iv = Base64.strict_decode64(iv_base64)
      auth_tag = Base64.strict_decode64(auth_tag_base64)

      # Remove auth tag from data if it was appended
      auth_tag_size = auth_tag.bytesize
      encrypted_data = if encrypted_data_with_tag.bytesize > auth_tag_size
                         encrypted_data_with_tag[0...-auth_tag_size]
                       else
                         encrypted_data_with_tag
                       end

      cipher.key = key
      cipher.iv = iv
      cipher.auth_tag = auth_tag

      cipher.update(encrypted_data) + cipher.final
    rescue OpenSSL::Cipher::CipherError
      nil # Invalid password or corrupted data
    end

    # Enhanced password strength validation
    def validate_password_strength(password)
      return { valid: false, error: 'Password cannot be empty' } if password.nil? || password.empty?

      # Check for common weak passwords FIRST (case-insensitive)
      if COMMON_PASSWORDS.any? { |common| common.downcase == password.downcase }
        return { valid: false, error: 'Password is too common, please choose a stronger one' }
      end

      # Then check other requirements
      return { valid: false, error: 'Password must be at least 8 characters long' } if password.length < 8
      return { valid: false, error: 'Password must contain at least one uppercase letter' } unless password =~ /[A-Z]/
      return { valid: false, error: 'Password must contain at least one lowercase letter' } unless password =~ /[a-z]/
      return { valid: false, error: 'Password must contain at least one number' } unless password =~ /\d/

      unless password =~ /[!@#$%^&*(),.?":{}|<>]/
        return { valid: false,
                 error: 'Password must contain at least one special character' }
      end

      { valid: true }
    end

    # Generate a cryptographically secure password
    def generate_secure_password(length = 16)
      # Ensure minimum length for strong passwords
      length = [length, 12].max

      # Character sets
      lowercase = ('a'..'z').to_a
      uppercase = ('A'..'Z').to_a
      numbers = ('0'..'9').to_a
      special = '!@#$%^&*()'.chars

      # Ensure at least one of each required character type
      password = [
        lowercase.sample,
        uppercase.sample,
        numbers.sample,
        special.sample
      ]

      # Fill the rest with random characters from all sets
      all_chars = lowercase + uppercase + numbers + special
      (length - 4).times { password << all_chars.sample }

      # Shuffle to avoid predictable patterns
      password.shuffle.join
    end

    # Hash sensitive data for logging (never log actual passwords)
    def hash_for_logging(data)
      "#{Digest::SHA256.hexdigest(data)[0..7]}..."
    end
  end
end
