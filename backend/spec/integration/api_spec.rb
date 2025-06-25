# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'API Endpoints' do
  include Rack::Test::Methods
  include ApiHelper

  describe 'POST /api/upload' do
    let(:test_data) { 'test file content' }
    let(:strong_password) { 'TestP@ssw0rd123!' }

    context 'with valid data' do
      it 'uploads a file successfully' do
        upload_file(test_data, strong_password)

        expect(last_response.status).to eq(200)
        expect(json_response).to have_key('file_id')
        expect(json_response['file_id']).to match(/^[a-zA-Z0-9]{8}$/)
      end

      it 'respects anonymous upload limit' do
        # Create data slightly over 100MB limit
        large_data = 'x' * (101 * 1024 * 1024) # 101MB
        upload_file(large_data, strong_password)

        expect(last_response.status).to eq(400)
        expect(json_response['error']).to include('too large')
      end
    end

    context 'with invalid data' do
      it 'rejects weak passwords' do
        upload_file(test_data, 'weak')

        expect(last_response.status).to eq(400)
        expect(json_response['error']).to include('characters')
      end

      it 'requires all fields' do
        post '/api/upload', {}.to_json, 'CONTENT_TYPE' => 'application/json'

        expect(last_response.status).to eq(400)
        expect(json_response['error']).to include('Missing required fields')
      end
    end

    context 'with authentication' do
      let(:auth_email) { "upload_test_#{SecureRandom.hex(8)}@example.com" }
      let(:user) { create_test_user(auth_email) }
      let(:token) { create_auth_token(user[:id], user[:email]) }

      it 'allows larger uploads for authenticated users' do
        # Test with smaller size that's still over anonymous limit
        large_data = 'x' * (150 * 1024 * 1024) # 150MB - over anon limit but reasonable
        upload_file(large_data, strong_password, headers: auth_headers(token))

        expect(last_response.status).to eq(200)
        expect(json_response).to have_key('file_id')
      end
    end
  end

  describe 'POST /api/download/:id' do
    let(:test_data) { 'test file content' }
    let(:password) { 'TestP@ssw0rd123!' }
    let(:file_id) do
      upload_file(test_data, password)
      json_response['file_id']
    end

    it 'downloads with correct password' do
      download_file(file_id, password)

      expect(last_response.status).to eq(200)
      expect(json_response['filename']).to eq('test.txt')
      expect(Base64.strict_decode64(json_response['encrypted_data'])).to eq(test_data)
    end

    it 'rejects incorrect password' do
      download_file(file_id, 'WrongP@ssw0rd123!')

      expect(last_response.status).to eq(401)
      expect(json_response['error']).to include('Invalid password')
    end

    it 'returns 404 for non-existent file' do
      download_file('notexist', password)

      expect(last_response.status).to eq(404)
      expect(json_response['error']).to include('not found')
    end
  end
end
