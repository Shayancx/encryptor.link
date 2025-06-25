# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication Endpoints' do
  include Rack::Test::Methods
  include ApiHelper

  let(:unique_email) { "test_#{SecureRandom.hex(8)}@example.com" }
  let(:valid_password) { 'TestP@ssw0rd123!' }

  describe 'POST /api/auth/register' do
    it 'creates a new account' do
      post '/api/auth/register', {
        login: unique_email,
        password: valid_password
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(json_response).to have_key('access_token')
      expect(json_response['account']['email']).to eq(unique_email)
    end

    it 'rejects duplicate emails' do
      # First registration
      post '/api/auth/register', {
        login: unique_email,
        password: valid_password
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      # Second registration with same email
      post '/api/auth/register', {
        login: unique_email,
        password: valid_password
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      expect(json_response['error']).to include('already registered')
    end

    it 'enforces password requirements' do
      post '/api/auth/register', {
        login: "weak_test_#{SecureRandom.hex(8)}@example.com",
        password: 'weak'
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      expect(json_response['error']).to include('8 characters')
    end
  end

  describe 'POST /api/auth/login' do
    let(:login_email) { "login_test_#{SecureRandom.hex(8)}@example.com" }

    before do
      # Create account first
      post '/api/auth/register', {
        login: login_email,
        password: valid_password
      }.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'logs in with valid credentials' do
      post '/api/auth/login', {
        login: login_email,
        password: valid_password
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(json_response).to have_key('access_token')
    end

    it 'rejects invalid credentials' do
      post '/api/auth/login', {
        login: login_email,
        password: 'WrongPassword!'
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(401)
      expect(json_response['error']).to include('Invalid')
    end
  end

  describe 'GET /api/auth/status' do
    let(:status_email) { "status_test_#{SecureRandom.hex(8)}@example.com" }

    let(:token) do
      post '/api/auth/register', {
        login: status_email,
        password: valid_password
      }.to_json, 'CONTENT_TYPE' => 'application/json'
      json_response['access_token']
    end

    it 'returns authenticated status with token' do
      get '/api/auth/status', nil, auth_headers(token)

      expect(last_response.status).to eq(200)
      expect(json_response['authenticated']).to be true
      expect(json_response['account']['upload_limit_mb']).to eq(4096)
    end

    it 'returns anonymous status without token' do
      get '/api/auth/status'

      expect(last_response.status).to eq(200)
      expect(json_response['authenticated']).to be false
      expect(json_response['upload_limit_mb']).to eq(100)
    end
  end
end
