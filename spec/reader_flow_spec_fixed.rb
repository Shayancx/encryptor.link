# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Reader, 'flow test fixed', fake_fs: true do
  let(:epub_path) { '/flow.epub' }
  let(:config) { EbookReader::Config.new }
  subject(:reader) { described_class.new(epub_path, config) }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: 'Flow',
                    language: 'en',
                    chapter_count: 2,
                    chapters: [
                      EbookReader::Models::Chapter.new(number: '1', title: 'Ch1', lines: Array.new(30) { |i| "line #{i}" }, metadata: nil),
                      EbookReader::Models::Chapter.new(number: '2', title: 'Ch2', lines: Array.new(30) { |i| "line #{i}" }, metadata: nil),
                    ])
  end

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter) { |i| doc.chapters[i] if i >= 0 && i < doc.chapters.size }
    allow(EbookReader::BookmarkManager).to receive(:get).and_return(
      [
        EbookReader::Models::Bookmark.new(chapter_index: 0, line_offset: 5, text_snippet: 'test bookmark', created_at: Time.now),
      ]
    )
    allow(EbookReader::BookmarkManager).to receive(:add)
    allow(EbookReader::BookmarkManager).to receive(:delete)
    allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)
    allow(EbookReader::ProgressManager).to receive(:save)
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::Terminal).to receive(:start_frame)
    allow(EbookReader::Terminal).to receive(:end_frame)
    allow(EbookReader::Terminal).to receive(:write)
    allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
  end

  it 'exercises multiple code paths through user interaction' do
    keys = ['t', 'j', 'j', "\r", 'B', 'j', 'd', 'B', "\e", 'v', '+', '-', 'n', 'p', 'G', 'g', '?', 'q']
    key_index = 0

    allow(EbookReader::Terminal).to receive(:read_key) do
      if key_index < keys.size
        key = keys[key_index]
        key_index += 1
        key
      end
    end

    allow(reader).to receive(:sleep)

    # Should complete without errors
    expect { reader.run }.not_to raise_error

    # Verify some state changes occurred
    expect(reader.instance_variable_get(:@running)).to be false
  end
end
