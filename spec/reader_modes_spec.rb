# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Reader, "modes" do
  let(:epub_path) { '/book.epub' }
  let(:config) { EbookReader::Config.new }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: "Test Book",
                    chapters: [
                      { title: "Chapter 1", lines: ["Line 1"] },
                      { title: "Chapter 2", lines: ["Line 1"] }
                    ],
                    chapter_count: 2)
  end
  let(:reader) { described_class.new(epub_path, config) }

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter).and_return(doc.chapters.first)
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::ProgressManager).to receive(:load)
    allow(EbookReader::ProgressManager).to receive(:save)
    allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
    allow(EbookReader::BookmarkManager).to receive(:add)
    allow(reader).to receive(:loop).and_yield
  end

  context 'when in help mode' do
    before do
      reader.instance_variable_set(:@mode, :help)
    end

    it 'returns to read mode on any key press' do
      allow(EbookReader::Terminal).to receive(:read_key).and_return('a')
      reader.send(:process_input, 'a')
      expect(reader.instance_variable_get(:@mode)).to eq(:read)
    end
  end

  context 'when in ToC mode' do
    before do
      reader.instance_variable_set(:@mode, :toc)
    end

    it 'navigates ToC up and down' do
      reader.instance_variable_set(:@toc_selected, 1)
      reader.send(:handle_toc_input, 'k')
      expect(reader.instance_variable_get(:@toc_selected)).to eq(0)
      reader.send(:handle_toc_input, 'j')
      expect(reader.instance_variable_get(:@toc_selected)).to eq(1)
    end

    it 'jumps to a chapter on Enter' do
      reader.instance_variable_set(:@toc_selected, 1)
      reader.send(:handle_toc_input, "\r")
      expect(reader.instance_variable_get(:@current_chapter)).to eq(1)
      expect(reader.instance_variable_get(:@mode)).to eq(:read)
    end

    it 'exits ToC mode on t or escape' do
      reader.send(:handle_toc_input, 't')
      expect(reader.instance_variable_get(:@mode)).to eq(:read)
      reader.instance_variable_set(:@mode, :toc)
      reader.send(:handle_toc_input, "\e")
      expect(reader.instance_variable_get(:@mode)).to eq(:read)
    end
  end

  context 'when in bookmarks mode' do
    let(:bookmarks) do
      [
        { 'chapter' => 0, 'line_offset' => 10, 'text' => 'Bookmark 1', 'timestamp' => '1' },
        { 'chapter' => 1, 'line_offset' => 20, 'text' => 'Bookmark 2', 'timestamp' => '2' }
      ]
    end

    before do
      reader.instance_variable_set(:@mode, :bookmarks)
      reader.instance_variable_set(:@bookmarks, bookmarks)
      allow(EbookReader::BookmarkManager).to receive(:delete)
    end

    it 'navigates bookmarks up and down' do
      reader.instance_variable_set(:@bookmark_selected, 1)
      reader.send(:handle_bookmarks_input, 'k')
      expect(reader.instance_variable_get(:@bookmark_selected)).to eq(0)
      reader.send(:handle_bookmarks_input, 'j')
      expect(reader.instance_variable_get(:@bookmark_selected)).to eq(1)
    end

    it 'jumps to a bookmark on Enter' do
      reader.instance_variable_set(:@bookmark_selected, 1)
      reader.send(:handle_bookmarks_input, "\r")
      expect(reader.instance_variable_get(:@current_chapter)).to eq(1)
      expect(reader.instance_variable_get(:@single_page)).to eq(20)
      expect(reader.instance_variable_get(:@mode)).to eq(:read)
    end

    it 'deletes a bookmark' do
      reader.instance_variable_set(:@bookmark_selected, 0)
      expect(EbookReader::BookmarkManager).to receive(:delete).with(epub_path, bookmarks.first)
      reader.send(:handle_bookmarks_input, 'd')
    end

    it 'handles empty bookmarks list' do
      reader.instance_variable_set(:@bookmarks, [])
      reader.send(:handle_bookmarks_input, 'j')
      expect(reader.instance_variable_get(:@bookmark_selected)).to eq(0)
      reader.send(:handle_bookmarks_input, "\r")
      expect(reader.instance_variable_get(:@mode)).to eq(:bookmarks) # no change
    end
  end
end
