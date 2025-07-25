# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Edge Cases" do
  describe EbookReader::Helpers::ReaderHelpers do
    let(:test_class) do
      Class.new { include EbookReader::Helpers::ReaderHelpers }
    end
    let(:helper) { test_class.new }

    it "handles nil word in wrap_line" do
      lines = ["word nil word"]
      allow(lines.first).to receive(:split).and_return(["word", nil, "word"])

      wrapped = helper.wrap_lines(lines, 50)
      expect(wrapped).to be_an(Array)
    end

    it "handles very long single words" do
      lines = ["verylongwordthatcannotbesplit"]
      wrapped = helper.wrap_lines(lines, 10)
      expect(wrapped).to include("verylongwordthatcannotbesplit")
    end
  end

  describe EbookReader::Config do
    it "handles missing config directory gracefully" do
      config = described_class.new
      allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::ENOENT)

      # Should not raise
      expect { config.save }.not_to raise_error
    end
  end

  describe EbookReader::EPUBFinder do
    it "handles timeout during scan" do
      allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)

      # Should return empty array or cached results
      result = described_class.scan_system(force_refresh: true)
      expect(result).to be_an(Array)
    end
  end

  describe EbookReader::MainMenu do
    it "handles interrupt during run" do
      menu = described_class.new
      allow(menu).to receive(:loop).and_raise(Interrupt)
      allow(EbookReader::Terminal).to receive(:cleanup)

      expect { menu.run }.to raise_error(SystemExit)
    end
  end
end
