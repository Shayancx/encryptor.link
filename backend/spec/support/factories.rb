# frozen_string_literal: true

FactoryBot.define do
  factory :account, class: Hash do
    email { Faker::Internet.unique.email }
    password_hash { BCrypt::Password.create('TestP@ssw0rd123!') }
    status_id { 'verified' }
    created_at { Time.now }

    initialize_with do
      attrs = attributes
      id = TEST_DB[:accounts].insert(attrs)
      attrs.merge(id: id)
    end
  end

  factory :encrypted_file, class: Hash do
    file_id { Crypto.generate_file_id }
    password_hash { BCrypt::Password.create('FileP@ssw0rd123!').to_s }
    salt { Crypto.generate_salt }
    file_path { "storage/test/#{file_id}.enc" }
    original_filename { "test_#{Faker::File.file_name}" }
    mime_type { 'application/octet-stream' }
    file_size { Faker::Number.between(from: 100, to: 10_000_000) }
    encryption_iv { Base64.strict_encode64(SecureRandom.random_bytes(16)) }
    created_at { Time.now }
    expires_at { Time.now + 86_400 }
    ip_address { Faker::Internet.ip_v4_address }
    account_id { nil }

    initialize_with do
      attrs = attributes
      FileUtils.mkdir_p(File.dirname(attrs[:file_path]))
      File.write(attrs[:file_path], SecureRandom.random_bytes(attrs[:file_size]))
      id = TEST_DB[:encrypted_files].insert(attrs)
      attrs.merge(id: id)
    end
  end

  factory :access_log, class: Hash do
    ip_address { Faker::Internet.ip_v4_address }
    endpoint { ['/api/upload', '/api/download'].sample }
    accessed_at { Time.now }

    initialize_with do
      attrs = attributes
      id = TEST_DB[:access_logs].insert(attrs)
      attrs.merge(id: id)
    end
  end

  factory :password_reset_token, class: Hash do
    account_id { create(:account)[:id] }
    token { SecureRandom.hex(32) }
    expires_at { Time.now + 3600 }
    created_at { Time.now }
    used { false }

    initialize_with do
      attrs = attributes
      id = TEST_DB[:password_reset_tokens].insert(attrs)
      attrs.merge(id: id)
    end
  end
end
