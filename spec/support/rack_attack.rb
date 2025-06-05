RSpec.configure do |config|
  config.before(:each, type: :feature) do
    Rack::Attack.enabled = false
  end

  config.after(:each, type: :feature) do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end
end
