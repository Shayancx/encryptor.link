# frozen_string_literal: true

require 'spec_helper'

class DummyRefactoredHelper
  include EbookReader::ReaderRefactored::NavigationHelpers
  include EbookReader::ReaderRefactored::DrawingHelpers
  include EbookReader::ReaderRefactored::BookmarkHelpers

  attr_accessor :left_page, :right_page, :single_page, :current_chapter, :config, :path

  def initialize(doc, config)
    @doc = doc
    @config = config
    @left_page = 0
    @right_page = 0
    @single_page = 0
    @current_chapter = 0
    @path = '/book.epub'
  end

  def get_layout_metrics(_width, _height)
    [40, 20]
  end

  def adjust_for_line_spacing(height)
    height
  end

  def wrap_lines(lines, _width)
    lines
  end

  def should_highlight_line?(_line)
    false
  end

  def draw_highlighted_line(line, row, col, width)
    Terminal.write(row, col, "H:#{line[0, width]}")
  end

  def page_offsets=(offset)
    @left_page = @single_page = offset
  end

  def save_progress; end
end

RSpec.describe EbookReader::ReaderRefactored do
  let(:doc) { double('doc') }
  let(:config) { double('config', view_mode: :single, show_page_numbers: true) }

  let(:dummy_class) do
    DummyRefactoredHelper
  end

  subject(:helper) { dummy_class.new(doc, config) }

  before do
    allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
    allow(EbookReader::Terminal).to receive(:write)
  end

  describe 'NavigationHelpers' do
    context '#calculate_navigation_params' do
      it 'returns nil when chapter missing' do
        allow(doc).to receive(:get_chapter).and_return(nil)
        expect(helper.calculate_navigation_params).to be_nil
      end

      it 'returns metrics when chapter exists' do
        chapter = { lines: Array.new(30, 'line') }
        allow(doc).to receive(:get_chapter).and_return(chapter)
        content_height, max_page, wrapped = helper.calculate_navigation_params
        expect(content_height).to eq(20)
        expect(max_page).to eq(10)
        expect(wrapped.size).to eq(30)
      end
    end

    context '#update_page_position_split?' do
      before { allow(config).to receive(:view_mode).and_return(:split) }

      it 'moves to next page' do
        expect(helper.update_page_position_split?(:next, 10, 20)).to be true
        expect(helper.right_page).to eq(10)
      end

      it 'prevents moving past max' do
        helper.right_page = 20
        expect(helper.update_page_position_split?(:next, 10, 20)).to be false
      end

      it 'moves previous' do
        helper.left_page = 10
        helper.right_page = 10
        expect(helper.update_page_position_split?(:prev, 10, 20)).to be true
        expect(helper.left_page).to eq(0)
      end
    end

    context '#update_page_position_single?' do
      it 'increments page offset' do
        expect(helper.update_page_position_single?(:next, 5, 15)).to be true
        expect(helper.single_page).to eq(5)
      end

      it 'stops at bounds' do
        helper.single_page = 15
        expect(helper.update_page_position_single?(:next, 5, 15)).to be false
      end
    end
  end

  describe 'DrawingHelpers' do
    it 'draws highlighted lines when needed' do
      allow(helper).to receive(:should_highlight_line?).and_return(true)
      helper.draw_line_with_formatting('Test', 2, 4, 10)
      expect(EbookReader::Terminal).to have_received(:write).with(2, 4, 'H:Test')
    end

    it 'draws plain lines otherwise' do
      helper.draw_line_with_formatting('Plain', 1, 2, 10)
      expect(EbookReader::Terminal).to have_received(:write).with(1, 2, /Plain/)
    end

    it 'calculates visible lines' do
      lines = (1..10).to_a
      expect(helper.calculate_visible_lines(lines, 2, 4)).to eq(lines[2...6])
    end

    it 'renders page indicator when enabled' do
      helper.render_page_indicator(2, 1, 10, 20, 0, 10, Array.new(30))
      expect(EbookReader::Terminal).to have_received(:write).with(21, anything, %r{1/3})
    end
  end

  describe 'BookmarkHelpers' do
    it 'creates bookmark data' do
      chapter = EbookReader::Models::Chapter.new(number: '1', title: 'Ch', lines: %w[one two three], metadata: nil)
      allow(doc).to receive(:get_chapter).and_return(chapter)
      data = helper.create_bookmark_data
      expect(data).to be_a(EbookReader::Models::Bookmark)
      expect(data.chapter_index).to eq(0)
      expect(data.text_snippet).to include('one')
    end

    it 'jumps to bookmark position' do
      bookmark = EbookReader::Models::Bookmark.new(chapter_index: 1, line_offset: 5, text_snippet: 'x', created_at: Time.now)
      helper.jump_to_bookmark_position(bookmark)
      expect(helper.current_chapter).to eq(1)
      expect(helper.left_page).to eq(5)
    end
  end
end
