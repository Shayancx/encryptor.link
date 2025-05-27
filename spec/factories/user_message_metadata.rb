FactoryBot.define do
  factory :user_message_metadata do
    user
    message_id { SecureRandom.uuid }
    encrypted_label { nil }
    encrypted_filename { nil }
    file_size { rand(100..10000) }
    message_type { %w[text file mixed].sample }
    created_at { Time.current }
    original_expiry { [ nil, 1.day.from_now, 1.week.from_now ].sample }
    accessed_count { 0 }
  end
end
