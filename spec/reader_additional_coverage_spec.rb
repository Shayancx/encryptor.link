# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Reader, 'additional coverage' do
  let(:epub_path) { '/book.epub' }
  let(:config) { EbookReader::Config.new }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    chapter_count: 2,
                    chapters: [
                      { title: 'Ch1', lines: Array.new(30) { |i| "line #{i}" } },
                      { title: 'Ch2', lines: Array.new(40) { |i| "line #{i}" } }
                    ])
  end

  subject(:reader) { described_class.new(epub_path, config) }

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
    allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)
    allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
    allow(reader).to receive(:wrap_lines) { |lines, _| lines }
    allow(reader).to receive(:save_progress)
  end

  describe '#position_at_chapter_end' do
    it 'sets offsets to end of chapter' do
      reader.instance_variable_set(:@current_chapter, 1)
      reader.send(:position_at_chapter_end)
      expect(reader.instance_variable_get(:@single_page)).to eq(39)
    end
  end

  describe '#update_page_map' do
    it 'calculates total pages for chapters' do
      reader.send(:update_page_map, 80, 24)
      expect(reader.instance_variable_get(:@total_pages)).to be > 0
    end
  end

  describe '#extract_bookmark_text' do
    it 'returns trimmed text snippet' do
      chapter = doc.chapters.first
      text = reader.send(:extract_bookmark_text, chapter, 5)
      expect(text.length).to be <= 50
    end
  end
end
