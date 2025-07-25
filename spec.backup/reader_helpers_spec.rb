# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Helpers::ReaderHelpers do
  let(:test_class) do
    Class.new do
      include EbookReader::Helpers::ReaderHelpers
    end
  end

  let(:helper) { test_class.new }

  describe "#wrap_lines" do
    it "wraps lines to specified width" do
      lines = ["This is a very long line that needs to be wrapped to fit the width"]
      wrapped = helper.wrap_lines(lines, 20)

      expect(wrapped.size).to be > 1
      wrapped.each { |line| expect(line.length).to be <= 20 }
    end

    it "preserves empty lines" do
      lines = ["First line", "", "Third line"]
      wrapped = helper.wrap_lines(lines, 50)

      expect(wrapped).to include("")
    end

    it "handles nil lines" do
      expect(helper.wrap_lines(nil, 50)).to eq([])
    end

    it "handles small width" do
      lines = ["Test"]
      expect(helper.wrap_lines(lines, 5)).to eq([])
    end

    it "splits on word boundaries" do
      lines = ["Hello world this is a test"]
      wrapped = helper.wrap_lines(lines, 15)

      expect(wrapped).to include("Hello world")
      expect(wrapped).to include("this is a test")
    end
  end
end
