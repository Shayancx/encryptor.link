# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::ProgressManager, fake_fs: true do
  let(:progress_file) { described_class::PROGRESS_FILE }
  let(:config_dir) { described_class::CONFIG_DIR }
  let(:book_path) { '/path/to/book.epub' }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  describe '.save' do
    it 'saves progress for a book' do
      described_class.save(book_path, 2, 15)
      progress = described_class.load(book_path)

      expect(progress['chapter']).to eq(2)
      expect(progress['line_offset']).to eq(15)
      expect(progress['timestamp']).to be_a(String)
    end

    it 'overwrites existing progress' do
      described_class.save(book_path, 1, 10)
      described_class.save(book_path, 2, 20)

      progress = described_class.load(book_path)
      expect(progress['chapter']).to eq(2)
      expect(progress['line_offset']).to eq(20)
    end
  end

  describe '.load' do
    it 'loads progress for a book' do
      described_class.save(book_path, 3, 25)
      progress = described_class.load(book_path)

      expect(progress).to be_a(Hash)
      expect(progress['chapter']).to eq(3)
    end

    it 'returns nil if no progress exists' do
      progress = described_class.load(book_path)
      expect(progress).to be_nil
    end
  end

  describe '.load_all' do
    it 'loads all progress data' do
      described_class.save('/book1.epub', 1, 10)
      described_class.save('/book2.epub', 2, 20)

      all_progress = described_class.load_all
      expect(all_progress.keys).to contain_exactly('/book1.epub', '/book2.epub')
    end

    it "returns empty hash if file doesn't exist" do
      expect(described_class.load_all).to eq({})
    end
  end
end
