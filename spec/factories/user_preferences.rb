FactoryBot.define do
  factory :user_preference do
    user { nil }
    default_ttl { 1 }
    default_views { 1 }
    theme_preference { "MyString" }
    encrypted_settings { "MyText" }
  end
end
