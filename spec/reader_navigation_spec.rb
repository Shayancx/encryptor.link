# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Reader, "navigation" do
  let(:epub_path) { '/book.epub' }
  let(:config) { EbookReader::Config.new }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: "Test Book",
                    chapters: [
                      EbookReader::Models::Chapter.new(number: '1', title: 'Ch1', lines: Array.new(100) { |i| "Line #{i + 1}" }, metadata: nil),
                      EbookReader::Models::Chapter.new(number: '2', title: 'Ch2', lines: ["Chapter 2, Line 1"], metadata: nil)
                    ],
                    chapter_count: 2)
  end
  let(:reader) { described_class.new(epub_path, config) }

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter).and_return(doc.chapters.first)
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::Terminal).to receive(:read_key).and_return('q') # quit loop
    allow(reader).to receive(:loop).and_yield
    allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)
    allow(EbookReader::ProgressManager).to receive(:save)
    allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
  end

  context 'when navigating chapters' do
    it 'goes to the next chapter' do
      reader.instance_variable_set(:@current_chapter, 0)
      allow(doc).to receive(:get_chapter).and_return(doc.chapters[1])
      reader.send(:handle_navigation_input, 'n')
      expect(reader.instance_variable_get(:@current_chapter)).to eq(1)
      expect(reader.instance_variable_get(:@single_page)).to eq(0)
    end

    it 'does not go past the last chapter' do
      reader.instance_variable_set(:@current_chapter, 1)
      reader.send(:handle_navigation_input, 'n')
      expect(reader.instance_variable_get(:@current_chapter)).to eq(1)
    end

    it 'goes to the previous chapter' do
      reader.instance_variable_set(:@current_chapter, 1)
      allow(doc).to receive(:get_chapter).and_return(doc.chapters[0])
      reader.send(:handle_navigation_input, 'p')
      expect(reader.instance_variable_get(:@current_chapter)).to eq(0)
      expect(reader.instance_variable_get(:@single_page)).to eq(0)
    end

    it 'does not go before the first chapter' do
      reader.instance_variable_set(:@current_chapter, 0)
      reader.send(:handle_navigation_input, 'p')
      expect(reader.instance_variable_get(:@current_chapter)).to eq(0)
    end
  end

  context 'when navigating within a chapter' do
    before do
      allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
      reader.send(:update_page_map, 80, 24)
    end

    it 'goes to the beginning of a chapter' do
      reader.instance_variable_set(:@single_page, 50)
      reader.send(:handle_navigation_input, 'g')
      expect(reader.instance_variable_get(:@single_page)).to eq(0)
    end

    it 'goes to the end of a chapter' do
      reader.send(:handle_navigation_input, 'G')
      chapter = doc.get_chapter(0)
      wrapped_lines = reader.send(:wrap_lines, chapter.lines, 72)
      content_height = reader.send(:adjust_for_line_spacing, 22)
      max_page = wrapped_lines.size - content_height
      expect(reader.instance_variable_get(:@single_page)).to eq(max_page)
    end
  end

  context 'when handling different view modes' do
    it 'toggles from split to single view' do
      config.view_mode = :split
      reader.send(:handle_reading_input, 'v')
      expect(config.view_mode).to eq(:single)
    end

    it 'toggles from single to split view' do
      config.view_mode = :single
      reader.send(:handle_reading_input, 'v')
      expect(config.view_mode).to eq(:split)
    end
  end

  context 'when adjusting line spacing' do
    it 'increases line spacing' do
      config.line_spacing = :compact
      reader.send(:increase_line_spacing)
      expect(config.line_spacing).to eq(:normal)
      reader.send(:increase_line_spacing)
      expect(config.line_spacing).to eq(:relaxed)
      reader.send(:increase_line_spacing) # Should not go beyond relaxed
      expect(config.line_spacing).to eq(:relaxed)
    end

    it 'decreases line spacing' do
      config.line_spacing = :relaxed
      reader.send(:decrease_line_spacing)
      expect(config.line_spacing).to eq(:normal)
      reader.send(:decrease_line_spacing)
      expect(config.line_spacing).to eq(:compact)
      reader.send(:decrease_line_spacing) # Should not go beyond compact
      expect(config.line_spacing).to eq(:compact)
    end
  end
end
