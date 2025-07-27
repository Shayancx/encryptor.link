# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::UI::ReaderRenderer do
  let(:config) { instance_double(EbookReader::Config, show_page_numbers: true) }
  let(:renderer) { described_class.new(config) }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: 'Test Book',
                    chapter_count: 10,
                    language: 'en_US')
  end

  before do
    allow(EbookReader::Terminal).to receive(:write)
  end

  describe '#render_header' do
    it 'renders title in single view read mode' do
      expect(EbookReader::Terminal).to receive(:write).with(1, 35, /Test Book/)
      renderer.render_header(doc, 80, :single, :read)
    end

    it 'renders controls in other modes' do
      expect(EbookReader::Terminal).to receive(:write).with(1, 1, /Reader/)
      expect(EbookReader::Terminal).to receive(:write).with(1, anything, /q:Quit/)
      renderer.render_header(doc, 80, :split, :read)
    end
  end

  describe '#render_footer' do
    let(:pages) { { current: 5, total: 100 } }
    let(:bookmarks) { [] }

    it 'renders page numbers in single view' do
      expect(EbookReader::Terminal).to receive(:write).with(24, 36, %r{5 / 100})
      renderer.render_footer(24, 80, doc, 0, pages, :single, :read, :normal, bookmarks)
    end

    it 'renders full footer in split view' do
      expect(EbookReader::Terminal).to receive(:write).with(23, 1, %r{\[1/10\]})
      expect(EbookReader::Terminal).to receive(:write).with(23, anything, /\[SPLIT\]/)
      renderer.render_footer(24, 80, doc, 0, pages, :split, :read, :normal, bookmarks)
    end

    it 'shows bookmark count' do
      bookmarks = [1, 2, 3]
      expect(EbookReader::Terminal).to receive(:write).with(anything, anything, /B3/)
      renderer.render_footer(24, 80, doc, 0, pages, :split, :read, :normal, bookmarks)
    end
  end
end
