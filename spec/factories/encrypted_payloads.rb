FactoryBot.define do
  factory :encrypted_payload do
    ciphertext { SecureRandom.random_bytes(100) }
    nonce { SecureRandom.random_bytes(12) }
    expires_at { 1.day.from_now }
    remaining_views { 1 }
    password_protected { false }
    password_salt { nil }

    trait :with_password do
      password_protected { true }
      password_salt { SecureRandom.random_bytes(16) }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :no_views_left do
      remaining_views { 0 }
    end

    trait :multi_view do
      remaining_views { 5 }
    end

    trait :many_views do
      remaining_views { 5 }  # Max allowed by validation
    end

    trait :burn_after_reading do
      burn_after_reading { true }
      remaining_views { 1 }
    end
  end
end
