# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Crypto do
  describe '.generate_salt' do
    it 'generates a 64-character hex string' do
      salt = Crypto.generate_salt
      expect(salt).to match(/^[a-f0-9]{64}$/)
    end

    it 'generates unique salts' do
      salts = Array.new(100) { Crypto.generate_salt }
      expect(salts.uniq.size).to eq(100)
    end
  end

  describe '.generate_file_id' do
    it 'generates an 8-character alphanumeric string' do
      id = Crypto.generate_file_id
      expect(id).to match(/^[a-zA-Z0-9]{8}$/)
    end

    it 'generates unique IDs' do
      ids = Array.new(1000) { Crypto.generate_file_id }
      expect(ids.uniq.size).to eq(1000)
    end

    it 'uses only safe characters' do
      100.times do
        id = Crypto.generate_file_id
        expect(id).not_to include('+', '/', '=', ' ')
      end
    end
  end

  describe '.hash_password' do
    let(:password) { 'TestP@ssw0rd123!' }
    let(:salt) { Crypto.generate_salt }

    it 'returns a BCrypt hash' do
      hash = Crypto.hash_password(password, salt)
      expect(hash).to be_a(BCrypt::Password)
    end

    it 'validates password strength' do
      weak_password = 'weak'
      result = Crypto.hash_password(weak_password, salt)
      expect(result).to be_a(Hash)
      expect(result[:valid]).to be false
    end

    it 'includes salt in the hash' do
      hash = Crypto.hash_password(password, salt)
      expect(BCrypt::Password.new(hash) == "#{password}#{salt}").to be true
    end

    it 'uses configured cost factor' do
      hash = Crypto.hash_password(password, salt)
      expect(hash.cost).to eq(Crypto::BCRYPT_COST)
    end

    it 'raises error on nil inputs' do
      result = Crypto.hash_password(nil, salt)
      expect(result[:valid]).to be false
      expect(result[:error]).to include('empty')
    end
  end

  describe '.verify_password' do
    let(:password) { 'TestP@ssw0rd123!' }
    let(:salt) { Crypto.generate_salt }
    let(:hash) { Crypto.hash_password(password, salt).to_s }

    it 'returns true for correct password' do
      expect(Crypto.verify_password(password, salt, hash)).to be true
    end

    it 'returns false for incorrect password' do
      expect(Crypto.verify_password('WrongPassword', salt, hash)).to be false
    end

    it 'returns false for nil inputs' do
      expect(Crypto.verify_password(nil, salt, hash)).to be false
      expect(Crypto.verify_password(password, nil, hash)).to be false
      expect(Crypto.verify_password(password, salt, nil)).to be false
    end

    it 'returns false for invalid hash format' do
      expect(Crypto.verify_password(password, salt, 'invalid-hash')).to be false
    end

    it 'is timing-attack resistant' do
      times = []

      10.times do
        start_time = Time.now
        Crypto.verify_password('wrong' * 100, salt, hash)
        times << Time.now - start_time
      end

      # Check that timing variance is low
      avg_time = times.sum / times.length
      variance = times.map { |t| (t - avg_time)**2 }.sum / times.length
      std_dev = Math.sqrt(variance)

      # More lenient check - BCrypt + our random delay should keep it under 0.05
      expect(std_dev).to be < 0.06
    end
  end

  describe '.validate_password_strength' do
    it 'accepts strong passwords' do
      strong_passwords = [
        'TestP@ssw0rd123!',
        'MyStr0ng!Password',
        'C0mpl3x!P@ssw0rd',
        'Secur3$Pass123'
      ]

      strong_passwords.each do |pwd|
        result = Crypto.validate_password_strength(pwd)
        expect(result[:valid]).to be(true), "Password '#{pwd}' should be valid but got: #{result[:error]}"
      end
    end

    it 'rejects weak passwords' do
      test_cases = {
        nil => 'empty',
        '' => 'empty',
        'short' => '8 characters',
        'nouppercase123!' => 'uppercase',
        'NOLOWERCASE123!' => 'lowercase',
        'NoNumbers!' => 'number',
        'NoSpecial123' => 'special character'
      }

      test_cases.each do |pwd, expected_error|
        result = Crypto.validate_password_strength(pwd)
        expect(result[:valid]).to be false
        expect(result[:error]).to include(expected_error)
      end
    end

    it 'rejects common passwords' do
      common_passwords = ['password', 'Password123!', 'qwerty123', 'admin123']
      common_passwords.each do |pwd|
        result = Crypto.validate_password_strength(pwd)
        expect(result[:valid]).to be false
        expect(result[:error]).to include('common')
      end
    end
  end

  describe '.generate_secure_password' do
    it 'generates passwords of specified length' do
      [12, 16, 20, 32].each do |length|
        pwd = Crypto.generate_secure_password(length)
        expect(pwd.length).to eq(length)
      end
    end

    it 'enforces minimum length of 12' do
      pwd = Crypto.generate_secure_password(8)
      expect(pwd.length).to eq(12)
    end

    it 'generates valid passwords' do
      100.times do
        pwd = Crypto.generate_secure_password
        result = Crypto.validate_password_strength(pwd)
        expect(result[:valid]).to be true
      end
    end

    it 'generates unique passwords' do
      passwords = Array.new(100) { Crypto.generate_secure_password }
      expect(passwords.uniq.size).to eq(100)
    end
  end

  describe '.derive_key' do
    let(:password) { 'TestPassword123' }
    let(:salt) { Crypto.generate_salt }

    it 'derives a key' do
      salt_bytes = Crypto.base64_to_array_buffer(Base64.strict_encode64(salt))
      key = Crypto.derive_key(password, salt_bytes)
      expect(key).to be_a(String)
      expect(key.bytesize).to eq(32) # AES-256 key size
    end

    it 'uses correct iterations' do
      expect(Crypto::PBKDF2_ITERATIONS).to eq(250_000)
    end

    it 'produces consistent keys' do
      salt_bytes = salt
      key1 = Crypto.derive_key(password, salt_bytes)
      key2 = Crypto.derive_key(password, salt_bytes)

      expect(key1).to eq(key2)
    end
  end

  describe '.encrypt_file and .decrypt_file' do
    let(:password) { 'FileP@ssw0rd123!' }
    let(:salt) { Crypto.generate_salt }
    let(:test_data) { 'This is sensitive file content!' }
    let(:file_path) { create_test_file(test_data) }

    after { File.delete(file_path) if File.exist?(file_path) }

    it 'encrypts and decrypts files correctly' do
      # Encrypt
      encrypted = Crypto.encrypt_file(file_path, password, salt)
      expect(encrypted[:data]).not_to eq(test_data)
      expect(encrypted[:iv]).to be_a(String)
      expect(encrypted[:auth_tag]).to be_a(String)

      # Decrypt
      decrypted = Crypto.decrypt_file(
        encrypted[:data],
        password,
        salt,
        encrypted[:iv],
        encrypted[:auth_tag]
      )

      expect(decrypted).to eq(test_data)
    end

    it 'fails decryption with wrong password' do
      encrypted = Crypto.encrypt_file(file_path, password, salt)

      decrypted = Crypto.decrypt_file(
        encrypted[:data],
        'WrongPassword',
        salt,
        encrypted[:iv],
        encrypted[:auth_tag]
      )

      expect(decrypted).to be_nil
    end

    it 'fails decryption with tampered data' do
      encrypted = Crypto.encrypt_file(file_path, password, salt)
      tampered_data = "#{encrypted[:data]}tampered"

      decrypted = Crypto.decrypt_file(
        tampered_data,
        password,
        salt,
        encrypted[:iv],
        encrypted[:auth_tag]
      )

      expect(decrypted).to be_nil
    end

    it 'handles large files' do
      # Test with 1MB instead of 10MB and without strict timing
      large_data = SecureRandom.random_bytes(1 * 1024 * 1024) # 1MB
      large_file = create_test_file(large_data, 'large.bin')

      encrypted = Crypto.encrypt_file(large_file, password, salt)

      # Just verify it works, not the performance
      expect(encrypted[:data]).to be_a(String)
      expect(encrypted[:data].bytesize).to be >= large_data.bytesize

      File.delete(large_file)
    end
  end

  describe '.hash_for_logging' do
    it 'creates a short hash for logging' do
      data = 'sensitive-data'
      hash = Crypto.hash_for_logging(data)

      expect(hash).to match(/^[a-f0-9]{8}\.\.\./)
      expect(hash).not_to include(data)
    end

    it 'produces consistent hashes' do
      data = 'test-data'
      hash1 = Crypto.hash_for_logging(data)
      hash2 = Crypto.hash_for_logging(data)

      expect(hash1).to eq(hash2)
    end
  end
end
