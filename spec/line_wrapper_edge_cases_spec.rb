# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Helpers::LineWrapper, 'edge cases' do
  describe '.wrap_terminal_write' do
    it 'handles zero max length' do
      pos = described_class::Coordinates.new(1, 1)
      allow(EbookReader::Terminal).to receive(:write)

      # Should use default length when given 0
      expect(EbookReader::Terminal).to receive(:write).with(1, 1, 'Text')
      described_class.wrap_terminal_write(pos, 'Text', 0)
    end

    it 'handles negative max length' do
      pos = described_class::Coordinates.new(1, 1)
      allow(EbookReader::Terminal).to receive(:write)

      # Should use default length when given negative
      expect(EbookReader::Terminal).to receive(:write).with(1, 1, 'Text')
      described_class.wrap_terminal_write(pos, 'Text', -1)
    end

    it 'handles nil text' do
      pos = described_class::Coordinates.new(1, 1)
      allow(EbookReader::Terminal).to receive(:write)

      # Should not call write for nil text
      expect(EbookReader::Terminal).not_to receive(:write)
      described_class.wrap_terminal_write(pos, nil, 20)
    end

    it 'handles empty text' do
      pos = described_class::Coordinates.new(1, 1)
      allow(EbookReader::Terminal).to receive(:write)

      # Should not call write for empty text
      expect(EbookReader::Terminal).not_to receive(:write)
      described_class.wrap_terminal_write(pos, '', 20)
    end
  end

  describe '.split_long_text' do
    it 'handles text with no spaces' do
      text = 'a' * 50
      parts = described_class.split_long_text(text, 20)

      expect(parts.all? { |p| p.length <= 20 }).to be true
      expect(parts.join).to eq(text)
    end

    it 'handles text with only spaces' do
      text = ' ' * 50
      parts = described_class.split_long_text(text, 20)

      expect(parts).not_to be_empty
    end

    it 'handles text with trailing spaces' do
      text = 'word ' * 10
      parts = described_class.split_long_text(text, 15)

      expect(parts.join).to eq(text)
    end

    it 'respects word boundaries when possible' do
      text = 'This is a sentence with several words in it'
      parts = described_class.split_long_text(text, 20)

      # Should prefer splitting at spaces
      expect(parts.first).to match(/\S$/) # Should not end with space
    end

    it 'handles edge case with zero max length' do
      text = 'Some text'
      parts = described_class.split_long_text(text, 0)

      # Should return original text to prevent infinite recursion
      expect(parts).to eq([text])
    end
  end
end
