# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Renderers::ContentRenderer do
  let(:config) { instance_double(EbookReader::Config, line_spacing: :normal, show_page_numbers: true) }
  let(:renderer) { described_class.new(config) }
  let(:chapter) do
    EbookReader::Models::Chapter.new(number: '1', title: 'Test Chapter',
                                     lines: ['Line 1', 'Line 2', 'Line 3'], metadata: nil)
  end

  before do
    allow(EbookReader::Terminal).to receive(:write)
    allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
    allow(renderer).to receive(:wrap_lines).and_return(chapter.lines)
  end

  describe '#draw_single_view' do
    it 'draws content in single column' do
      renderer.draw_single_view(chapter, 80, 24, 0)
      expect(EbookReader::Terminal).to have_received(:write).at_least(:once)
    end

    it 'centers content horizontally' do
      expect(renderer).to receive(:center_column).and_call_original
      renderer.draw_single_view(chapter, 80, 24, 0)
    end

    it 'handles nil chapter gracefully' do
      expect { renderer.draw_single_view(nil, 80, 24, 0) }.not_to raise_error
    end
  end

  describe '#draw_split_view' do
    it 'draws content in two columns' do
      renderer.draw_split_view(chapter, 80, 24, 0, 1)
      expect(EbookReader::Terminal).to have_received(:write).at_least(5).times
    end

    it 'draws chapter header' do
      expect(renderer).to receive(:draw_chapter_header).with(chapter, 80)
      renderer.draw_split_view(chapter, 80, 24, 0, 1)
    end

    it 'draws divider between columns' do
      expect(renderer).to receive(:draw_divider)
      renderer.draw_split_view(chapter, 80, 24, 0, 1)
    end
  end

  describe 'layout calculations' do
    it 'calculates single column width correctly' do
      width = renderer.send(:calculate_single_column_width, 100)
      expect(width).to be <= 100
      expect(width).to be >= EbookReader::Constants::UIConstants::MIN_COLUMN_WIDTH
    end

    it 'calculates split column width correctly' do
      width = renderer.send(:calculate_split_column_width, 80)
      expect(width).to eq(37) # (80 - 5) / 2
    end

    it 'adjusts content height for relaxed spacing' do
      allow(config).to receive(:line_spacing).and_return(:relaxed)
      height = renderer.send(:calculate_content_height, 24, :single)
      expect(height).to eq(10) # (24 - 2 - 2) / 2
    end
  end

  describe 'page number display' do
    it 'shows page numbers when enabled' do
      expect(renderer).to receive(:draw_page_number)
      renderer.send(:draw_column, 3, 1, 40, 20, ['Line 1'], 0, true)
    end

    it 'skips page numbers when disabled' do
      expect(renderer).not_to receive(:draw_page_number)
      renderer.send(:draw_column, 3, 1, 40, 20, ['Line 1'], 0, false)
    end
  end
end
