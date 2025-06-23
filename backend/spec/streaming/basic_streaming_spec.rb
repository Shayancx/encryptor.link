require 'spec_helper'

RSpec.describe 'Basic Streaming Upload' do
  include Rack::Test::Methods
  include ApiHelper
  
  describe 'POST /api/streaming/initialize' do
    it 'creates a session with valid parameters' do
      post '/api/streaming/initialize', {
        filename: 'test.txt',
        fileSize: 1000,
        mimeType: 'text/plain',
        password: 'TestP@ssw0rd123!',
        totalChunks: 1,
        chunkSize: 1000
      }.to_json, 'CONTENT_TYPE' => 'application/json'
      
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data).to have_key('session_id')
      expect(data).to have_key('file_id')
    end
  end
  
  describe 'GET /api/streaming/health' do
    it 'returns health status' do
      get '/api/streaming/health'
      
      expect(last_response.status).to eq(200)
      health = JSON.parse(last_response.body)
      expect(health['status']).to eq('healthy')
    end
  end
end
