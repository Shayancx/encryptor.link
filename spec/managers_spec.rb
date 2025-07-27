# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Managers", fake_fs: true do
  let(:config_dir) { EbookReader::Config::CONFIG_DIR }
  let(:book_path) { "/path/to/my_book.epub" }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  describe EbookReader::ProgressManager do
    it 'handles corrupted progress file' do
      File.write(described_class::PROGRESS_FILE, '{"invalid"}')
      expect(described_class.load_all).to eq({})
    end
  end

  describe EbookReader::BookmarkManager do
    it 'builds a correct bookmark entry' do
      entry = described_class.build_entry(1, 10, "A sample text")
      expect(entry).to be_a(EbookReader::Models::Bookmark)
      expect(entry.chapter_index).to eq(1)
      expect(entry.line_offset).to eq(10)
      expect(entry.text_snippet).to eq("A sample text")
      expect(entry.created_at).not_to be_nil
    end
  end

  describe EbookReader::RecentFiles do
    it 'handles corrupted recent files list' do
      File.write(described_class::RECENT_FILE, 'invalid')
      expect(described_class.load).to be_empty
    end
  end
end
