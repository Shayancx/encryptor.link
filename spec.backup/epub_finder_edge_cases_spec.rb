# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::EPUBFinder, "edge cases" do
  describe '.scan_system' do
    it 'handles directory access errors' do
      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:entries).and_raise(Errno::EACCES)

      result = described_class.scan_system(force_refresh: true)
      expect(result).to be_an(Array)
    end

    it 'handles symbolic link loops' do
      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:entries).and_raise(Errno::ELOOP)

      result = described_class.scan_system(force_refresh: true)
      expect(result).to be_an(Array)
    end

    it 'handles corrupted cache with partial data' do
      cache_data = { 'files' => nil, 'timestamp' => Time.now.iso8601 }
      allow(File).to receive(:exist?).with(described_class::CACHE_FILE).and_return(true)
      allow(File).to receive(:read).with(described_class::CACHE_FILE).and_return(cache_data.to_json)

      result = described_class.scan_system
      expect(result).to be_an(Array)
    end

    it 'handles files with special characters' do
      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:entries).and_return(['.', '..', 'book[special].epub', 'book with spaces.epub'])
      allow(File).to receive(:directory?).and_return(false)
      allow(File).to receive(:readable?).and_return(true)
      allow(File).to receive(:size).and_return(1000)
      allow(File).to receive(:mtime).and_return(Time.now)

      result = described_class.scan_system(force_refresh: true)
      expect(result.map { |f| f['name'] }).to include('book[special]', 'book with spaces')
    end

    it 'skips zero-byte files' do
      allow(Dir).to receive(:exist?).and_return(true)
      allow(Dir).to receive(:entries).and_return(['.', '..', 'empty.epub', 'valid.epub'])
      allow(File).to receive(:directory?).and_return(false)
      allow(File).to receive(:readable?).and_return(true)
      allow(File).to receive(:size).with(/empty/).and_return(0)
      allow(File).to receive(:size).with(/valid/).and_return(1000)
      allow(File).to receive(:mtime).and_return(Time.now)

      result = described_class.scan_system(force_refresh: true)
      expect(result.map { |f| f['name'] }).to include('valid')
      expect(result.map { |f| f['name'] }).not_to include('empty')
    end
  end

  describe 'private methods' do
    it 'handles permission errors when checking directory existence' do
      expect(described_class.send(:safe_directory_exists?, '/root/protected')).to be false
    end
  end
end
