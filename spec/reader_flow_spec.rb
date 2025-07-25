require 'spec_helper'

RSpec.describe EbookReader::Reader, 'extended flow', fake_fs: true do
  let(:epub_path) { '/flow.epub' }
  let(:config) { EbookReader::Config.new }
  subject(:reader) { described_class.new(epub_path, config) }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: 'Flow',
                    language: 'en',
                    chapter_count: 2,
                    chapters: [
                      { title: 'Ch1', lines: Array.new(30) { |i| "line #{i}" } },
                      { title: 'Ch2', lines: Array.new(30) { |i| "line #{i}" } }
                    ])
  end

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter) { |i| doc.chapters[i] }
    allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
    allow(EbookReader::BookmarkManager).to receive(:add)
    allow(EbookReader::BookmarkManager).to receive(:delete)
    allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)
    allow(EbookReader::ProgressManager).to receive(:save)
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::Terminal).to receive(:start_frame)
    allow(EbookReader::Terminal).to receive(:end_frame)
    allow(EbookReader::Terminal).to receive(:write)
    allow(EbookReader::Terminal).to receive(:size).and_return([24,80])
  end

  it 'exercises multiple code paths' do
    keys = ['t','j','j','\r','B','j','d','\e','v','+','-','n','p','G','g','Q']
    allow(EbookReader::Terminal).to receive(:read_key).and_return(*keys)
    expect { reader.run }.to raise_error(SystemExit)
  end
end
