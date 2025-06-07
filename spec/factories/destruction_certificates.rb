FactoryBot.define do
  factory :destruction_certificate do
    encrypted_payload
    destruction_reason { "test_destruction" }
    payload_metadata { { test: true } }
  end
end
