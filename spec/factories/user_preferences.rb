FactoryBot.define do
  factory :user_preference do
    user
    default_ttl { 86400 } # 1 day
    default_views { 1 }
    theme_preference { "auto" }
    encrypted_settings { nil }
  end
end
