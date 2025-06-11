# Simple logging configuration for development
if Rails.env.development?
  Rails.application.configure do
    # Use simple string-based log tags to avoid push_tags error
    config.log_tags = ["REQUEST"]
    config.log_level = :info
  end
end
