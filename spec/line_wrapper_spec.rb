# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/helpers/line_wrapper'

describe EbookReader::Helpers::LineWrapper do
  describe ".wrap" do
    it "wraps a long line of text" do
      text = "This is a long line of text that should be wrapped."
      wrapped_text = EbookReader::Helpers::LineWrapper.wrap(text, 20)
      expected_text = "This is a long line\nof text that should\nbe wrapped."
      expect(wrapped_text).to eq(expected_text)
    end

    it "does not wrap a short line of text" do
      text = "This is a short line."
      wrapped_text = EbookReader::Helpers::LineWrapper.wrap(text, 30)
      expect(wrapped_text).to eq(text)
    end

    it "handles text with newlines" do
      text = "This is the first line.\nThis is the second line."
      wrapped_text = EbookReader::Helpers::LineWrapper.wrap(text, 20)
      expected_text = "This is the first\nline.\nThis is the second\nline."
      expect(wrapped_text).to eq(expected_text)
    end

    it "handles an empty string" do
      text = ""
      wrapped_text = EbookReader::Helpers::LineWrapper.wrap(text, 20)
      expect(wrapped_text).to eq("")
    end

    it "handles a width of zero or less" do
      text = "This is a test."
      expect(EbookReader::Helpers::LineWrapper.wrap(text, 0)).to eq("This\nis\na\ntest.")
      expect(EbookReader::Helpers::LineWrapper.wrap(text, -5)).to eq("This\nis\na\ntest.")
    end
  end
end
