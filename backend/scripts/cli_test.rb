#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'base64'
require 'optparse'

class EncryptorCLI
  API_BASE = ENV['API_URL'] || 'http://localhost:9292/api'

  def self.upload(file_path, password)
    unless File.exist?(file_path)
      puts "Error: File not found: #{file_path}"
      return
    end

    # Read and encode file
    file_data = File.read(file_path, mode: 'rb')
    encoded_data = Base64.strict_encode64(file_data)

    # Determine MIME type (simple detection)
    mime_type = case File.extname(file_path).downcase
                when '.txt' then 'text/plain'
                when '.pdf' then 'application/pdf'
                when '.jpg', '.jpeg' then 'image/jpeg'
                when '.png' then 'image/png'
                else 'application/octet-stream'
                end

    # Make upload request
    uri = URI("#{API_BASE}/upload")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      encrypted_data: encoded_data,
      password: password,
      filename: File.basename(file_path),
      mime_type: mime_type,
      iv: Base64.strict_encode64('0' * 16) # Placeholder IV
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)

    if response.code == '200'
      puts 'Upload successful!'
      puts "File ID: #{result['file_id']}"
      puts "Download URL: #{result['download_url']}"
      puts "Expires at: #{result['expires_at']}"
    else
      puts "Upload failed: #{result['error']}"
    end
  end

  def self.download(file_id, password, output_path = nil)
    uri = URI("#{API_BASE}/download/#{file_id}")
    uri.query = URI.encode_www_form(password: password)

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)

    response = http.request(request)
    result = JSON.parse(response.body)

    if response.code == '200'
      # Decode file data
      file_data = Base64.strict_decode64(result['encrypted_data'])

      # Determine output path
      output_path ||= result['filename'] || "download_#{file_id}"

      # Write file
      File.open(output_path, 'wb') do |f|
        f.write(file_data)
      end

      puts 'Download successful!'
      puts "File saved to: #{output_path}"
      puts "Size: #{result['file_size']} bytes"
    else
      puts "Download failed: #{result['error']}"
    end
  end
end

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: cli_test.rb [command] [options]'

  opts.on('-u', '--upload FILE', 'Upload a file') do |file|
    options[:command] = :upload
    options[:file] = file
  end

  opts.on('-d', '--download ID', 'Download a file by ID') do |id|
    options[:command] = :download
    options[:file_id] = id
  end

  opts.on('-p', '--password PASSWORD', 'Password for encryption/decryption') do |password|
    options[:password] = password
  end

  opts.on('-o', '--output PATH', 'Output path for download') do |path|
    options[:output] = path
  end
end.parse!

# Execute command
case options[:command]
when :upload
  unless options[:file] && options[:password]
    puts 'Error: Upload requires --upload FILE and --password PASSWORD'
    exit 1
  end
  EncryptorCLI.upload(options[:file], options[:password])
when :download
  unless options[:file_id] && options[:password]
    puts 'Error: Download requires --download ID and --password PASSWORD'
    exit 1
  end
  EncryptorCLI.download(options[:file_id], options[:password], options[:output])
else
  puts 'Error: Please specify --upload or --download'
  exit 1
end
