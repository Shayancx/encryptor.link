# frozen_string_literal: true

module ApiHelper
  def json_response
    JSON.parse(last_response.body)
  end

  def auth_headers(token)
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end

  def upload_file(data, password, options = {})
    params = {
      encrypted_data: Base64.strict_encode64(data),
      password: password,
      filename: options[:filename] || 'test.txt',
      mime_type: options[:mime_type] || 'text/plain',
      iv: Base64.strict_encode64(SecureRandom.random_bytes(16)),
      ttl_hours: options[:ttl_hours] || 24
    }

    headers = options[:headers] || {}
    post '/api/upload', params.to_json, headers.merge('CONTENT_TYPE' => 'application/json')
  end

  def download_file(file_id, password, options = {})
    headers = options[:headers] || {}
    post "/api/download/#{file_id}",
         { password: password }.to_json,
         headers.merge('CONTENT_TYPE' => 'application/json')
  end
end

RSpec.configure do |config|
  config.include ApiHelper
end
