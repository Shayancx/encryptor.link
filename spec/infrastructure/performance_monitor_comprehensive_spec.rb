# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Infrastructure::PerformanceMonitor do
  before { described_class.clear }

  describe '.time' do
    it 'measures execution time' do
      result = described_class.time('operation') do
        sleep 0.01
        'result'
      end

      expect(result).to eq('result')
      stats = described_class.stats('operation')
      expect(stats[:count]).to eq(1)
      expect(stats[:total]).to be > 0.01
    end

    it 'tracks memory usage' do
      described_class.time('memory_test') { 'x' * 1000 }

      metrics = described_class.metrics['memory_test']
      expect(metrics.first[:memory_delta]).to be_a(Numeric)
    end

    it 'logs slow operations' do
      allow(EbookReader::Infrastructure::Logger).to receive(:warn)

      described_class.time('slow_op') { sleep 1.1 }

      expect(EbookReader::Infrastructure::Logger).to have_received(:warn)
        .with('Slow operation detected', hash_including(label: 'slow_op'))
    end
  end

  describe '.stats' do
    it 'calculates statistics correctly' do
      3.times { |i| described_class.time('test') { sleep 0.01 * (i + 1) } }

      stats = described_class.stats('test')
      expect(stats[:count]).to eq(3)
      expect(stats[:average]).to be_between(0.01, 0.03)
      expect(stats[:min]).to be < stats[:max]
    end

    it 'returns nil for unknown metrics' do
      expect(described_class.stats('unknown')).to be_nil
    end
  end
end
