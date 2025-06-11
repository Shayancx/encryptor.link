# config/initializers/secure_headers.rb
if defined?(SecureHeaders)
  SecureHeaders::Configuration.default do |config|
    # Strong CSP configuration
    config.csp = {
      default_src: %w('self'),
      script_src: %w('self' 'unsafe-inline'),
      style_src: %w('self' 'unsafe-inline'),
      img_src: %w('self' data:),
      connect_src: %w('self' localhost:*),
      font_src: %w('self'),
      object_src: %w('none'),
      frame_src: %w('self'),
      frame_ancestors: %w('self'),
      form_action: %w('self')
    }

    # Enable XSS protection
    config.x_xss_protection = "1; mode=block"
    
    # Enable X-Frame-Options
    config.x_frame_options = "SAMEORIGIN"
    
    # Enable X-Content-Type-Options
    config.x_content_type_options = "nosniff"
    
    # Enable HSTS (only in production)
    if Rails.env.production?
      config.hsts = "max-age=31536000; includeSubDomains"
    end
  end
end
