# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Infrastructure::Logger do
  let(:test_output) { StringIO.new }

  before do
    described_class.output = test_output
    described_class.level = :debug
  end

  after do
    described_class.output = $stderr
    described_class.level = :info
  end

  describe 'log levels' do
    it 'logs all levels when set to debug' do
      described_class.debug('debug message')
      described_class.info('info message')
      described_class.warn('warn message')
      described_class.error('error message')
      described_class.fatal('fatal message')

      output = test_output.string
      expect(output).to include('debug message')
      expect(output).to include('info message')
      expect(output).to include('warn message')
      expect(output).to include('error message')
      expect(output).to include('fatal message')
    end

    it 'filters messages below configured level' do
      described_class.level = :warn

      described_class.debug('debug')
      described_class.info('info')
      described_class.warn('warn')

      output = test_output.string
      expect(output).not_to include('debug')
      expect(output).not_to include('info')
      expect(output).to include('warn')
    end
  end

  describe '.with_context' do
    it 'adds context to log entries' do
      described_class.with_context(user_id: 123, request_id: 'abc') do
        described_class.info('test message')
      end

      output = test_output.string
      expect(output).to include('"user_id":123')
      expect(output).to include('"request_id":"abc"')
    end

    it 'restores previous context after block' do
      described_class.with_context(outer: true) do
        described_class.with_context(inner: true) do
          described_class.info('inner')
        end
        described_class.info('outer')
      end

      lines = test_output.string.split("\n")
      expect(lines[0]).to include('"inner":true')
      expect(lines[1]).not_to include('"inner":true')
    end
  end

  describe 'error handling' do
    it 'never crashes the application' do
      described_class.output = nil
      expect { described_class.error('test') }.not_to raise_error
    end
  end
end
