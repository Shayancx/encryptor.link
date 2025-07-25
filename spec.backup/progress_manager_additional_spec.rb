# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::ProgressManager, fake_fs: true do
  let(:progress_file) { described_class::PROGRESS_FILE }
  let(:config_dir) { described_class::CONFIG_DIR }
  let(:path) { '/extra.epub' }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  describe '.load_all' do
    it 'returns empty hash on JSON parse error' do
      File.write(progress_file, '{')
      expect(described_class.load_all).to eq({})
    end
  end

  describe '.save' do
    it 'handles file write errors gracefully' do
      allow(File).to receive(:write).and_raise(StandardError)
      expect { described_class.save(path, 1, 1) }.not_to raise_error
    end

    it 'stores ISO8601 timestamp' do
      described_class.save(path, 0, 0)
      data = JSON.parse(File.read(progress_file))
      expect { Time.iso8601(data[path]['timestamp']) }.not_to raise_error
    end
  end
end
