# config/initializers/secure_headers.rb
if defined?(SecureHeaders)
  SecureHeaders::Configuration.default do |config|
    # Strong CSP configuration
    config.csp = {
      default_src: %w('self'),
      script_src: %w('self' 'unsafe-inline' 'unsafe-eval' localhost:* 127.0.0.1:*),
      style_src: %w('self' 'unsafe-inline'),
      img_src: %w('self' data: blob:),
      connect_src: %w('self' localhost:* 127.0.0.1:* ws://localhost:* wss://localhost:*),
      font_src: %w('self' data:),
      object_src: %w('none'),
      frame_src: %w('self'),
      frame_ancestors: %w('self'),
      form_action: %w('self'),
      base_uri: %w('self'),
      manifest_src: %w('self')
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
    
    # Referrer Policy
    config.referrer_policy = %w(strict-origin-when-cross-origin)
    
    # Permissions Policy - only configure if the method exists
    if config.respond_to?(:permissions_policy=)
      config.permissions_policy = {
        camera: %w(none),
        geolocation: %w(none),
        microphone: %w(none),
        payment: %w(none),
        usb: %w(none)
      }
    else
      # For older versions of secure_headers gem, use the application controller
      # to set permissions policy headers manually if needed
      Rails.logger.info "SecureHeaders gem version doesn't support permissions_policy configuration"
    end
  end
end
