# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Reader, 'render sections' do
  let(:epub_path) { '/book.epub' }
  let(:config) { EbookReader::Config.new }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: 'Book',
                    language: 'en',
                    chapter_count: 2,
                    chapters: [
                      EbookReader::Models::Chapter.new(number: '1', title: 'Ch1',
                                                       lines: %w[a b c d e], metadata: nil),
                      EbookReader::Models::Chapter.new(number: '2', title: 'Ch2',
                                                       lines: %w[f g h i j], metadata: nil),
                    ])
  end

  subject(:reader) { described_class.new(epub_path, config) }

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter) { |i| doc.chapters[i] }
    allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
    allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)
    allow(EbookReader::Terminal).to receive(:write)
  end

  it 'draws the help screen' do
    reader.send(:draw_help_screen, 20, 80)
    expect(EbookReader::Terminal).to have_received(:write).at_least(5).times
  end

  it 'draws the toc screen' do
    reader.send(:draw_toc_screen, 20, 80)
    expect(EbookReader::Terminal).to have_received(:write).at_least(5).times
  end

  it 'draws the bookmarks screen with bookmarks' do
    reader.instance_variable_set(:@bookmarks, [
                                   EbookReader::Models::Bookmark.new(chapter_index: 0, line_offset: 0, text_snippet: 'hi', created_at: Time.now),
                                 ])
    reader.send(:draw_bookmarks_screen, 20, 80)
    expect(EbookReader::Terminal).to have_received(:write).at_least(5).times
  end

  it 'draws split and single screens' do
    reader.instance_variable_set(:@current_chapter, 0)
    reader.send(:draw_split_screen, 24, 80)
    reader.send(:draw_single_screen, 24, 80)
    expect(EbookReader::Terminal).to have_received(:write).at_least(5).times
  end
end
