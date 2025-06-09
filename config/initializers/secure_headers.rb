if Rails.env.development?
  Rails.application.config.action_dispatch.default_headers = {
    "X-Frame-Options" => "DENY",
    "X-Content-Type-Options" => "nosniff",
    "X-XSS-Protection" => "0"
  }
else
  Rails.application.config.action_dispatch.default_headers = {
    "X-Frame-Options" => "DENY",
    "X-Content-Type-Options" => "nosniff",
    "X-XSS-Protection" => "0",
    "Content-Security-Policy" => "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; font-src 'self';"
  }
end
