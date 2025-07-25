# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/progress_manager'

describe EbookReader::ProgressManager, fake_fs: true do
  let(:progress_file) { EbookReader::Constants::PROGRESS_FILE }
  let(:config_dir) { EbookReader::Constants::CONFIG_DIR }
  let(:book_path) { "/path/to/book.epub" }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  describe ".load" do
    it "loads the progress if the file exists" do
      progress_data = { book_path => 5 }
      File.write(progress_file, progress_data.to_yaml)
      progress_manager = described_class.load
      expect(progress_manager.progress).to eq(progress_data)
    end

    it "returns an empty hash if the file does not exist" do
      progress_manager = described_class.load
      expect(progress_manager.progress).to be_empty
    end
  end

  describe "#update_progress" do
    it "updates the progress for a book" do
      progress_manager = described_class.new
      progress_manager.update_progress(book_path, 10)
      expect(progress_manager.progress[book_path]).to eq(10)
    end
  end

  describe "#progress_for" do
    it "returns the progress for a book" do
      progress_manager = described_class.new
      progress_manager.update_progress(book_path, 10)
      expect(progress_manager.progress_for(book_path)).to eq(10)
    end

    it "returns 0 if no progress is found" do
      progress_manager = described_class.new
      expect(progress_manager.progress_for(book_path)).to eq(0)
    end
  end

  describe "#save" do
    it "saves the progress to a file" do
      progress_manager = described_class.new
      progress_manager.update_progress(book_path, 10)
      progress_manager.save
      loaded_progress = YAML.load_file(progress_file)
      expect(loaded_progress[book_path]).to eq(10)
    end
  end
end
