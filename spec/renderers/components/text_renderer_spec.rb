# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Renderers::Components::TextRenderer do
  let(:config) { instance_double(EbookReader::Config, highlight_quotes: true) }
  let(:renderer) { described_class.new(config) }

  before do
    allow(EbookReader::Terminal).to receive(:write)
  end

  describe '#render_line' do
    it 'renders a line of text' do
      expect(EbookReader::Terminal).to receive(:write).with(5, 10, anything)
      renderer.render_line('Test line', 5, 10, 50)
    end

    it 'handles nil line gracefully' do
      expect { renderer.render_line(nil, 5, 10, 50) }.not_to raise_error
    end

    it 'ignores invalid positions' do
      expect(EbookReader::Terminal).not_to receive(:write)
      renderer.render_line('Test', -1, 10, 50)
      renderer.render_line('Test', 5, -1, 50)
    end
  end

  describe '#format_line' do
    it 'truncates long lines' do
      long_line = 'a' * 100
      formatted = renderer.format_line(long_line, 20)
      expect(formatted).to include('a' * 20)
    end

    it 'applies highlighting when enabled' do
      line = 'Chinese poets wrote "beautiful verses"'
      formatted = renderer.format_line(line, 100)
      expect(formatted).to include(EbookReader::Terminal::ANSI::CYAN)
      expect(formatted).to include(EbookReader::Terminal::ANSI::ITALIC)
    end

    it 'skips highlighting when disabled' do
      allow(config).to receive(:highlight_quotes).and_return(false)
      line = 'Chinese poets wrote "beautiful verses"'
      formatted = renderer.format_line(line, 100)
      expect(formatted).not_to include(EbookReader::Terminal::ANSI::CYAN)
    end
  end

  describe 'smart truncation' do
    it 'breaks at word boundaries when possible' do
      line = 'This is a test of smart truncation'
      truncated = renderer.send(:truncate_line, line, 15)
      expect(truncated).to eq('This is a...')
    end

    it 'handles lines with no spaces' do
      line = 'verylongwordwithoutspaces'
      truncated = renderer.send(:truncate_line, line, 10)
      expect(truncated).to eq('verylongwo')
    end

    it 'handles zero width' do
      truncated = renderer.send(:truncate_line, 'test', 0)
      expect(truncated).to eq('')
    end
  end

  describe 'highlighting' do
    it 'highlights multiple keywords' do
      line = 'Chinese poets and philosophers celebrated fragrance'
      highlighted = renderer.send(:apply_highlighting, line)

      expect(highlighted.scan(EbookReader::Terminal::ANSI::CYAN).count).to eq(4)
    end

    it 'highlights nested quotes' do
      line = '"He said \'hello\' to me"'
      highlighted = renderer.send(:apply_highlighting, line)

      expect(highlighted).to include(EbookReader::Terminal::ANSI::ITALIC)
    end

    it 'preserves original text' do
      line = 'Normal text without special content'
      highlighted = renderer.send(:apply_highlighting, line)

      # Remove ANSI codes to check content
      clean_text = highlighted.gsub(/\e\[[0-9;]*m/, '')
      expect(clean_text).to eq(line)
    end
  end
end
