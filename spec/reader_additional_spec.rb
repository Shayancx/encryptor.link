# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Reader do
  let(:epub_path) { '/test.epub' }

  let(:config) do
    instance_double(EbookReader::Config,
                    view_mode: :single,
                    line_spacing: :normal,
                    show_page_numbers: true,
                    highlight_quotes: true)
  end

  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: 'Title',
                    language: 'en_US',
                    chapter_count: 2,
                    chapters: [
                      EbookReader::Models::Chapter.new(number: '1', title: 'Ch1', lines: Array.new(50, 'line'), metadata: nil),
                      EbookReader::Models::Chapter.new(number: '2', title: 'Ch2', lines: Array.new(60, 'line'), metadata: nil)
                    ])
  end

  before do
    allow(config).to receive(:view_mode=)
    allow(config).to receive(:line_spacing=)
    allow(config).to receive(:save)
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter) { |i| doc.chapters[i] }
    allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
    allow(EbookReader::BookmarkManager).to receive(:add)
    allow(EbookReader::BookmarkManager).to receive(:delete)
    allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)
    allow(EbookReader::ProgressManager).to receive(:save)
  end

  subject(:reader) { described_class.new(epub_path, config) }

  describe '#update_page_map and #calculate_current_pages' do
    it 'computes pages and totals' do
      reader.send(:update_page_map, 80, 24)
      expect(reader.instance_variable_get(:@page_map)).to eq([3, 4])
      expect(reader.instance_variable_get(:@total_pages)).to eq(7)

      reader.instance_variable_set(:@single_page, 34)
      pages = reader.send(:calculate_current_pages, 24, 80)
      expect(pages).to eq({ current: 3, total: 7 })
    end
  end

  describe '#adjust_for_line_spacing' do
    it 'handles different spacing modes' do
      allow(config).to receive(:line_spacing).and_return(:compact)
      expect(reader.send(:adjust_for_line_spacing, 10)).to eq(10)

      allow(config).to receive(:line_spacing).and_return(:relaxed)
      expect(reader.send(:adjust_for_line_spacing, 10)).to eq(5)

      allow(config).to receive(:line_spacing).and_return(:normal)
      expect(reader.send(:adjust_for_line_spacing, 10)).to eq(8)
    end
  end

  describe 'highlight helpers' do
    it 'highlights keywords and quotes' do
      line = 'Chinese poets say "hello"'
      kw = reader.send(:highlight_keywords, line)
      expect(kw).to include(EbookReader::Terminal::ANSI::CYAN)

      q = reader.send(:highlight_quotes, kw)
      expect(q).to include(EbookReader::Terminal::ANSI::ITALIC)
    end
  end

  describe 'view and spacing adjustments' do
    it 'toggles view mode' do
      expect(config).to receive(:view_mode=).with(:split)
      reader.send(:toggle_view_mode)
    end

    it 'increases and decreases line spacing' do
      allow(config).to receive(:line_spacing).and_return(:compact)
      reader.send(:increase_line_spacing)
      expect(config).to have_received(:line_spacing=).with(:normal)

      allow(config).to receive(:line_spacing).and_return(:normal)
      reader.send(:decrease_line_spacing)
      expect(config).to have_received(:line_spacing=).with(:compact)
    end
  end

  describe 'scrolling and paging' do
    it 'scrolls up and down' do
      reader.send(:scroll_down, 10)
      expect(reader.instance_variable_get(:@single_page)).to eq(1)
      reader.send(:scroll_up)
      expect(reader.instance_variable_get(:@single_page)).to eq(0)
    end

    it 'navigates pages' do
      reader.send(:next_page, 5, 10)
      expect(reader.instance_variable_get(:@single_page)).to eq(5)
      reader.send(:prev_page, 5)
      expect(reader.instance_variable_get(:@single_page)).to eq(0)

      reader.send(:go_to_end, 5, 10)
      expect(reader.instance_variable_get(:@single_page)).to eq(10)
    end
  end

  describe 'helper ranges' do
    it 'calculates toc and bookmark ranges' do
      reader.instance_variable_set(:@toc_selected, 5)
      range = reader.send(:calculate_toc_visible_range, 5, 10)
      expect(range).to eq(3...8)

      reader.instance_variable_set(:@bookmark_selected, 4)
      reader.instance_variable_set(:@bookmarks, Array.new(10) { |i| EbookReader::Models::Bookmark.new(chapter_index: 0, line_offset: i, text_snippet: 't', created_at: Time.now) })
      range2 = reader.send(:calculate_bookmark_visible_range, 4)
      expect(range2).to eq(2...6)
    end
  end

  describe '#build_help_lines' do
    it 'returns help text' do
      lines = reader.send(:build_help_lines)
      expect(lines).to include('Navigation Keys:')
    end
  end
end
