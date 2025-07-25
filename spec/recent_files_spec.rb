# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::RecentFiles, fake_fs: true do
  let(:recent_file) { described_class::RECENT_FILE }
  let(:config_dir) { described_class::CONFIG_DIR }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  describe ".add" do
    it "adds a file to recent list" do
      described_class.add("/path/to/book.epub")
      recent = described_class.load

      expect(recent.size).to eq(1)
      expect(recent.first['path']).to eq("/path/to/book.epub")
      expect(recent.first['name']).to eq("book")
      expect(recent.first['accessed']).to be_a(String)
    end

    it "moves existing file to top" do
      described_class.add("/book1.epub")
      described_class.add("/book2.epub")
      described_class.add("/book1.epub")

      recent = described_class.load
      expect(recent.first['path']).to eq("/book1.epub")
      expect(recent.size).to eq(2)
    end

    it "limits to MAX_RECENT_FILES" do
      15.times { |i| described_class.add("/book#{i}.epub") }
      recent = described_class.load

      expect(recent.size).to eq(described_class::MAX_RECENT_FILES)
    end
  end

  describe ".load" do
    it "loads recent files list" do
      described_class.add("/book.epub")
      recent = described_class.load

      expect(recent).to be_an(Array)
      expect(recent.first).to include('path', 'name', 'accessed')
    end

    it "returns empty array if file doesn't exist" do
      expect(described_class.load).to eq([])
    end

    it "handles corrupted file gracefully" do
      File.write(recent_file, "invalid json")
      expect(described_class.load).to eq([])
    end
  end
end
