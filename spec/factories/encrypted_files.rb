FactoryBot.define do
  factory :encrypted_file do
    encrypted_payload
    file_data { Base64.encode64(SecureRandom.random_bytes(1000)) }
    file_name { Faker::File.file_name }
    file_type { "application/octet-stream" }
    file_size { rand(100..10000) }
  end
end
