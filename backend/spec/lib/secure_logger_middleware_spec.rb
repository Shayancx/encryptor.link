# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SecureLoggerMiddleware do
  let(:app) { double('app') }
  let(:middleware) { SecureLoggerMiddleware.new(app) }

  describe '#call' do
    it 'filters passwords from query strings' do
      env = {
        'QUERY_STRING' => 'user=test&password=secret123&token=abc',
        'REQUEST_URI' => '/api/test?user=test&password=secret123&token=abc'
      }

      expect(app).to receive(:call) do |filtered_env|
        expect(filtered_env['QUERY_STRING']).to eq('user=test&password=[FILTERED]&token=abc')
        expect(filtered_env['REQUEST_URI']).to eq('/api/test?user=test&password=[FILTERED]&token=abc')
      end

      middleware.call(env)
    end

    it 'handles missing query strings' do
      env = { 'PATH_INFO' => '/api/test' }

      expect(app).to receive(:call).with(env)

      middleware.call(env)
    end

    it 'handles multiple password parameters' do
      env = {
        'QUERY_STRING' => 'password=secret1&new_password=secret2&old_password=secret3'
      }

      expect(app).to receive(:call) do |filtered_env|
        expect(filtered_env['QUERY_STRING']).to eq('password=[FILTERED]&new_password=[FILTERED]&old_password=[FILTERED]')
      end

      middleware.call(env)
    end
  end
end
