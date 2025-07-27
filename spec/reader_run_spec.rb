# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Reader, 'run loop' do
  let(:epub_path) { '/book.epub' }
  let(:config) { EbookReader::Config.new }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: 'Book',
                    language: 'en',
                    chapter_count: 2,
                    chapters: [
                      EbookReader::Models::Chapter.new(number: '1', title: 'Ch1', lines: Array.new(5) { |i| "L#{i}" }, metadata: nil),
                      EbookReader::Models::Chapter.new(number: '2', title: 'Ch2', lines: Array.new(5) { |i| "L#{i}" }, metadata: nil),
                    ])
  end

  subject(:reader) { described_class.new(epub_path, config) }

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter).and_return(doc.chapters.first)
    allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
    allow(EbookReader::BookmarkManager).to receive(:add)
    allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)
    allow(EbookReader::ProgressManager).to receive(:save)
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::Terminal).to receive(:start_frame)
    allow(EbookReader::Terminal).to receive(:end_frame)
    allow(EbookReader::Terminal).to receive(:write)
    allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
    allow(EbookReader::Terminal).to receive(:read_key).and_return(
      'j', 'n', 'b', 'B', 'd', "\e", 't', "\r", 'v', '?', 'x', 'q'
    )
    allow(reader).to receive(:sleep)
  end

  it 'runs through a short main loop' do
    expect { reader.run }.not_to raise_error
  end
end
