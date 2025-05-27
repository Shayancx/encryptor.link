FactoryBot.define do
  factory :user do
    email_address { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }

    # Ensure email is properly set
    after(:build) do |user|
      user.email = user.email_address if user.email.blank?
    end
  end
end
