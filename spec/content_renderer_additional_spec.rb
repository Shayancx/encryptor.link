require 'spec_helper'

RSpec.describe EbookReader::Renderers::ContentRenderer do
  let(:config) { EbookReader::Config.new }
  let(:renderer) { described_class.new(config) }

  before do
    allow(EbookReader::Terminal).to receive(:write)
    allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
  end

  describe 'private drawing helpers' do
    it 'draws a divider of correct height' do
      renderer.send(:draw_divider, 10, 20)
      expect(EbookReader::Terminal).to have_received(:write).exactly(6).times
    end

    it 'draws page numbers when allowed' do
      lines = Array.new(30, 'a')
      expect { renderer.send(:draw_page_number, 3, 1, 20, 5, 5, 5, lines) }.not_to raise_error
    end

    it 'draws lines with relaxed spacing' do
      config.line_spacing = :relaxed
      lines = %w[a b c d e]
      renderer.send(:draw_lines, lines, 0, 5, 3, 1, 10, 2)
      expect(EbookReader::Terminal).to have_received(:write).at_least(2).times
    end
  end
end
