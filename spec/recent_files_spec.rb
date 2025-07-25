# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/recent_files'

describe EbookReader::RecentFiles, fake_fs: true do
  let(:recent_files_file) { EbookReader::Constants::RECENT_FILES_FILE }
  let(:config_dir) { EbookReader::Constants::CONFIG_DIR }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  describe ".load" do
    it "loads the recent files list if it exists" do
      files = ["/path/to/book1.epub", "/path/to/book2.epub"]
      File.write(recent_files_file, files.to_yaml)
      recent_files = described_class.load
      expect(recent_files.files).to eq(files)
    end

    it "returns an empty list if the file does not exist" do
      recent_files = described_class.load
      expect(recent_files.files).to be_empty
    end
  end

  describe "#add" do
    it "adds a file to the list" do
      recent_files = described_class.new
      recent_files.add("/path/to/book.epub")
      expect(recent_files.files).to include("/path/to/book.epub")
    end

    it "moves the most recent file to the top" do
      recent_files = described_class.new
      recent_files.add("/path/to/book1.epub")
      recent_files.add("/path/to/book2.epub")
      recent_files.add("/path/to/book1.epub")
      expect(recent_files.files.first).to eq("/path/to/book1.epub")
    end

    it "does not add more than 10 files" do
      recent_files = described_class.new
      15.times { |i| recent_files.add("/path/to/book#{i}.epub") }
      expect(recent_files.files.size).to eq(10)
    end
  end

  describe "#save" do
    it "saves the recent files to a file" do
      recent_files = described_class.new
      recent_files.add("/path/to/book.epub")
      recent_files.save
      loaded_files = YAML.load_file(recent_files_file)
      expect(loaded_files).to include("/path/to/book.epub")
    end
  end
end
