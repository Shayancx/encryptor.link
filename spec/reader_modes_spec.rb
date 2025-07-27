# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::ReaderModes do
  let(:reader) { instance_double(EbookReader::Reader) }
  let(:config) { instance_double(EbookReader::Config, view_mode: :single) }
  let(:document) do
    instance_double(EbookReader::EPUBDocument,
                    chapters: [EbookReader::Models::Chapter.new(number: '1', title: 'Ch1',
                                                                lines: ['Line 1'], metadata: nil)],
                    chapter_count: 1)
  end

  before do
    allow(reader).to receive(:config).and_return(config)
    allow(reader).to receive(:send).with(:doc).and_return(document)
    allow(reader).to receive(:current_chapter).and_return(0)
    allow(reader).to receive(:send).with(:bookmarks).and_return([])
    allow(EbookReader::Terminal).to receive(:write)
  end

  describe EbookReader::ReaderModes::ReadingMode do
    subject(:mode) { described_class.new(reader) }

    it 'draws based on view mode' do
      allow(reader).to receive(:send).with(:draw_single_screen, 24, 80)
      mode.draw(24, 80)
    end

    it 'handles navigation input' do
      expect(reader).to receive(:scroll_down)
      mode.handle_input('j')
    end
  end

  describe EbookReader::ReaderModes::HelpMode do
    subject(:mode) { described_class.new(reader) }

    it 'draws help content' do
      mode.draw(24, 80)
      expect(EbookReader::Terminal).to have_received(:write).at_least(5).times
    end

    it 'returns to read mode on any key' do
      expect(reader).to receive(:switch_mode).with(:read)
      mode.handle_input('x')
    end
  end
end
