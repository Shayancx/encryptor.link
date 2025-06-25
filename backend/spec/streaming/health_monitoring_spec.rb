# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Streaming Upload Health Monitoring' do
  include Rack::Test::Methods
  include ApiHelper

  describe 'GET /api/streaming/health' do
    it 'returns health status' do
      get '/api/streaming/health'

      expect(last_response.status).to eq(200)
      health = JSON.parse(last_response.body)

      expect(health['status']).to eq('healthy')
      expect(health['streaming']).to include(
        'temp_storage' => true,
        'active_sessions' => be_a(Integer),
        'database' => true
      )
    end

    it 'reports active session count' do
      # Create some sessions
      3.times do |i|
        StreamingUpload.create_session(
          "health_test_#{i}.txt",
          100,
          'text/plain',
          1,
          100,
          'test_hash',
          'test_salt'
        )
      end

      get '/api/streaming/health'

      health = JSON.parse(last_response.body)
      expect(health['streaming']['active_sessions']).to be >= 3
    end
  end
end
