# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Helpers::LineWrapper do
  describe ".wrap_terminal_write" do
    before do
      allow(EbookReader::Terminal).to receive(:write)
    end

    it "writes short text directly" do
      expect(EbookReader::Terminal).to receive(:write).with(5, 10, "Short text")
      described_class.wrap_terminal_write(5, 10, "Short text")
    end

    it "wraps long text across multiple lines" do
      long_text = "a" * 150
      expect(EbookReader::Terminal).to receive(:write).exactly(2).times
      described_class.wrap_terminal_write(5, 10, long_text, 120)
    end
  end

  describe ".split_long_text" do
    it "splits text at max length" do
      text = "This is a very long line that needs to be split"
      parts = described_class.split_long_text(text, 20)

      expect(parts.size).to be >= 2
      parts[0..-2].each { |part| expect(part.length).to be <= 20 }
      expect(parts.join).to eq(text)
    end

    it "splits text and preserves all content" do
      text = "This is a test of the splitting algorithm"
      parts = described_class.split_long_text(text, 20)

      # Just verify all text is preserved
      expect(parts.join).to eq(text)
      expect(parts.first).to start_with("This is a")
    end
  end
end
