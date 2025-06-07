FactoryBot.define do
  factory :admin_user do
    email { 'admin@example.com' }
    password { 'password' }
    role { 'super_admin' }
    active { true }
  end
end
