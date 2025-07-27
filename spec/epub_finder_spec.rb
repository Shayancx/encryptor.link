# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::EPUBFinder do
  before do
    allow(File).to receive(:expand_path).and_call_original
    allow(Dir).to receive(:exist?).and_return(false)
    allow(Dir).to receive(:exist?).with(File.expand_path('~/Books')).and_return(true)
    allow(Dir).to receive(:entries).and_return(['.', '..', 'book1.epub', 'subdir'])
    allow(File).to receive(:directory?).and_return(false)
    allow(File).to receive(:directory?).with(File.join(File.expand_path('~/Books'), 'subdir')).and_return(true)
    allow(File).to receive(:readable?).and_return(true)
    allow(File).to receive(:size).and_return(1000)
    allow(File).to receive(:mtime).and_return(Time.now)
  end

  describe '.scan_system' do
    it 'scans for epub files' do
      epubs = described_class.scan_system(force_refresh: true)
      expect(epubs).to be_an(Array)
    end

    it 'uses cache when not forced' do
      # First scan
      described_class.scan_system(force_refresh: true)

      # Second scan should use cache
      allow(described_class).to receive(:cache_expired?).and_return(false)
      expect(described_class).not_to receive(:perform_scan)
      described_class.scan_system
    end

    it 'respects MAX_FILES limit' do
      stub_const("#{described_class}::MAX_FILES", 1)
      epubs = described_class.scan_system(force_refresh: true)
      expect(epubs.size).to be <= 1
    end
  end

  describe '.clear_cache' do
    it 'removes cache file' do
      expect(FileUtils).to receive(:rm_f).with(described_class::CACHE_FILE)
      described_class.clear_cache
    end
  end
end
