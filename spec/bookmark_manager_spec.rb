# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/bookmark_manager'

describe EbookReader::BookmarkManager, fake_fs: true do
  let(:bookmarks_file) { EbookReader::Constants::BOOKMARKS_FILE }
  let(:config_dir) { EbookReader::Constants::CONFIG_DIR }
  let(:book_path) { "/path/to/book.epub" }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  describe ".load" do
    it "loads the bookmarks if the file exists" do
      bookmarks_data = { book_path => [1, 5] }
      File.write(bookmarks_file, bookmarks_data.to_yaml)
      bookmark_manager = described_class.load
      expect(bookmark_manager.bookmarks).to eq(bookmarks_data)
    end

    it "returns an empty hash if the file does not exist" do
      bookmark_manager = described_class.load
      expect(bookmark_manager.bookmarks).to be_empty
    end
  end

  describe "#add_bookmark" do
    it "adds a bookmark for a book" do
      bookmark_manager = described_class.new
      bookmark_manager.add_bookmark(book_path, 10)
      expect(bookmark_manager.bookmarks[book_path]).to include(10)
    end

    it "does not add a duplicate bookmark" do
      bookmark_manager = described_class.new
      bookmark_manager.add_bookmark(book_path, 10)
      bookmark_manager.add_bookmark(book_path, 10)
      expect(bookmark_manager.bookmarks[book_path].size).to eq(1)
    end
  end

  describe "#remove_bookmark" do
    it "removes a bookmark for a book" do
      bookmark_manager = described_class.new
      bookmark_manager.add_bookmark(book_path, 10)
      bookmark_manager.remove_bookmark(book_path, 10)
      expect(bookmark_manager.bookmarks[book_path]).to be_empty
    end
  end

  describe "#has_bookmark?" do
    it "returns true if a bookmark exists" do
      bookmark_manager = described_class.new
      bookmark_manager.add_bookmark(book_path, 10)
      expect(bookmark_manager.has_bookmark?(book_path, 10)).to be true
    end

    it "returns false if a bookmark does not exist" do
      bookmark_manager = described_class.new
      expect(bookmark_manager.has_bookmark?(book_path, 10)).to be false
    end
  end

  describe "#save" do
    it "saves the bookmarks to a file" do
      bookmark_manager = described_class.new
      bookmark_manager.add_bookmark(book_path, 10)
      bookmark_manager.save
      loaded_bookmarks = YAML.load_file(bookmarks_file)
      expect(loaded_bookmarks[book_path]).to include(10)
    end
  end
end
