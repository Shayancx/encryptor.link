FactoryBot.define do
  factory :audit_log do
    event_type { 'test_event' }
    severity { 'info' }
  end
end
