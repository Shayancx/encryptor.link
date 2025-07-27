# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::BookmarkManager, fake_fs: true do
  let(:bookmarks_file) { described_class::BOOKMARKS_FILE }
  let(:config_dir) { described_class::CONFIG_DIR }
  let(:book_path) { '/path/to/book.epub' }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  describe '.add' do
    it 'adds a bookmark for a book' do
      described_class.add(book_path, 0, 10, 'Sample text')
      bookmarks = described_class.get(book_path)
      expect(bookmarks.size).to eq(1)
      bm = bookmarks.first
      expect(bm.chapter_index).to eq(0)
      expect(bm.line_offset).to eq(10)
      expect(bm.text_snippet).to eq('Sample text')
    end

    it 'sorts bookmarks by chapter and line offset' do
      described_class.add(book_path, 1, 20, 'Text 2')
      described_class.add(book_path, 1, 10, 'Text 1')
      described_class.add(book_path, 0, 30, 'Text 0')

      bookmarks = described_class.get(book_path)
      expect(bookmarks[0].chapter_index).to eq(0)
      expect(bookmarks[1].line_offset).to eq(10)
      expect(bookmarks[2].line_offset).to eq(20)
    end
  end

  describe '.get' do
    it 'returns bookmarks for a book' do
      described_class.add(book_path, 0, 10, 'Sample text')
      bookmarks = described_class.get(book_path)
      expect(bookmarks).to be_an(Array)
      expect(bookmarks.size).to eq(1)
    end

    it 'returns empty array if no bookmarks exist' do
      bookmarks = described_class.get(book_path)
      expect(bookmarks).to eq([])
    end
  end

  describe '.delete' do
    it 'removes a specific bookmark' do
      described_class.add(book_path, 0, 10, 'Sample text')
      bookmarks = described_class.get(book_path)

      described_class.delete(book_path, bookmarks.first)
      expect(described_class.get(book_path)).to be_empty
    end
  end

  describe '.load_all' do
    it 'loads all bookmarks from file' do
      bookmarks_data = { book_path => [{ 'chapter' => 0, 'line_offset' => 10 }] }
      File.write(bookmarks_file, JSON.pretty_generate(bookmarks_data))

      expect(described_class.load_all).to eq(bookmarks_data)
    end

    it "returns empty hash if file doesn't exist" do
      expect(described_class.load_all).to eq({})
    end

    it 'returns empty hash on parse error' do
      File.write(bookmarks_file, 'invalid json')
      expect(described_class.load_all).to eq({})
    end
  end
end
