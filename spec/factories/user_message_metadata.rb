FactoryBot.define do
  factory :user_message_metadatum do
    user { nil }
    message_id { "" }
    encrypted_label { "MyText" }
    encrypted_filename { "MyText" }
    file_size { 1 }
    message_type { "MyString" }
    created_at { "2025-05-25 22:15:14" }
    original_expiry { "2025-05-25 22:15:14" }
    accessed_count { 1 }
  end
end
