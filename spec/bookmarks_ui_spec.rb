require 'spec_helper'

RSpec.describe EbookReader::Concerns::BookmarksUI do
  let(:doc) { double('doc', get_chapter: { title: 'Ch1' }) }
  let(:dummy_class) do
    Class.new do
      include EbookReader::Concerns::BookmarksUI
      include EbookReader::Constants::UIConstants
      attr_accessor :bookmarks, :bookmark_selected
      def initialize(doc, bookmarks)
        @doc = doc
        @bookmarks = bookmarks
        @bookmark_selected = 0
      end
    end
  end

  let(:bookmarks) do
    [
      { 'chapter' => 0, 'line_offset' => 10, 'text' => 'First' },
      { 'chapter' => 1, 'line_offset' => 20, 'text' => 'Second' }
    ]
  end

  subject(:ui) { dummy_class.new(doc, bookmarks) }

  before do
    allow(EbookReader::Terminal).to receive(:write)
    stub_const('EbookReader::Concerns::BookmarksUI::MIN_COLUMN_WIDTH',
               EbookReader::Constants::UIConstants::MIN_COLUMN_WIDTH)
  end

  it 'draws full screen with bookmarks' do
    ui.draw_bookmarks_screen(24, 80)
    expect(EbookReader::Terminal).to have_received(:write).at_least(5).times
  end

  it 'draws empty state' do
    empty = dummy_class.new(doc, [])
    empty.draw_bookmarks_screen(24, 80)
    expect(EbookReader::Terminal).to have_received(:write).at_least(2).times
  end

  it 'calculates visible range' do
    ui.bookmark_selected = 1
    range = ui.calculate_bookmark_visible_range(2)
    expect(range).to eq(0...2)
  end

  it 'renders selected bookmark item' do
    ui.draw_bookmark_item(bookmarks.first, 'Ch1', 0, 4, 80)
    expect(EbookReader::Terminal).to have_received(:write).at_least(3).times
  end

  it 'renders unselected bookmark item' do
    ui.draw_bookmark_item(bookmarks.last, 'Ch1', 1, 6, 80)
    expect(EbookReader::Terminal).to have_received(:write).at_least(2).times
  end

  it 'draws footer' do
    ui.draw_bookmarks_footer(24)
    expect(EbookReader::Terminal).to have_received(:write).with(23, anything, /Navigate/)
  end
end
