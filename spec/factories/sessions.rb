FactoryBot.define do
  factory :session do
    user
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" }
  end
end
