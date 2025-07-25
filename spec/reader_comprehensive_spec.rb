# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Reader, "comprehensive" do
  let(:epub_path) { '/book.epub' }
  let(:config) { EbookReader::Config.new }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: "Test",
                    language: "en",
                    chapter_count: 2,
                    chapters: [
                      { title: "Ch1", lines: ["Line 1", "Line 2"] },
                      { title: "Ch2", lines: ["Line 3", "Line 4"] }
                    ])
  end
  let(:reader) { described_class.new(epub_path, config) }

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter) { |i| doc.chapters[i] }
    allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
    allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)
    allow(EbookReader::ProgressManager).to receive(:save)
    allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
  end

  describe 'display edge cases' do
    it 'handles invalid column parameters gracefully' do
      expect { reader.send(:draw_column, 1, 1, 0, 1, [], 0, false) }.not_to raise_error
      expect { reader.send(:draw_column, 1, 1, 10, 0, [], 0, false) }.not_to raise_error
      expect { reader.send(:draw_column, 1, 1, 10, 10, nil, 0, false) }.not_to raise_error
    end

    it 'calculates row correctly for different line spacings' do
      config.line_spacing = :relaxed
      expect(reader.send(:calculate_row, 5, 2)).to eq(9)

      config.line_spacing = :normal
      expect(reader.send(:calculate_row, 5, 2)).to eq(7)
    end

    it 'handles terminal boundary checks' do
      allow(EbookReader::Terminal).to receive(:size).and_return([10, 80])
      allow(EbookReader::Terminal).to receive(:write)

      # Should not write past terminal height
      reader.send(:draw_lines, ["Line 1"] * 20, 0, 20, 1, 1, 80, 20)

      # Verify it respects boundaries
      expect(EbookReader::Terminal).to have_received(:write).at_most(8).times
    end
  end

  describe 'navigation boundaries' do
    it 'handles space key navigation' do
      reader.send(:handle_navigation_input, ' ')
      expect(reader.instance_variable_get(:@single_page)).to be >= 0
    end

    it 'handles chapter boundaries during prev_page' do
      reader.instance_variable_set(:@current_chapter, 1)
      reader.instance_variable_set(:@single_page, 0)

      reader.send(:prev_page, 10)
      expect(reader.instance_variable_get(:@current_chapter)).to eq(0)
    end
  end

  describe 'error document creation' do
    it 'creates proper error document structure' do
      error_doc = reader.send(:create_error_document, "Test error")

      expect(error_doc.title).to eq('Error Loading EPUB')
      expect(error_doc.language).to eq('en_US')
      expect(error_doc.chapter_count).to eq(1)

      chapter = error_doc.get_chapter(0)
      expect(chapter[:lines]).to include("Test error")
      expect(chapter[:lines]).to include("Press 'q' to return to the menu")
    end
  end

  describe 'bookmark handling' do
    it 'handles bookmark deletion when selected index becomes invalid' do
      reader.instance_variable_set(:@bookmarks, [
                                     { 'chapter' => 0, 'line_offset' => 0, 'text' => 'B1' },
                                     { 'chapter' => 0, 'line_offset' => 5, 'text' => 'B2' }
                                   ])
      reader.instance_variable_set(:@bookmark_selected, 1)

      allow(EbookReader::BookmarkManager).to receive(:delete)
      allow(EbookReader::BookmarkManager).to receive(:get).and_return([])

      reader.send(:delete_selected_bookmark)
      expect(reader.instance_variable_get(:@bookmark_selected)).to eq(0)
    end
  end
end
