# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Config, fake_fs: true do
  let(:config_dir) { described_class::CONFIG_DIR }
  let(:config_file) { described_class::CONFIG_FILE }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  describe "#initialize" do
    it "sets default values" do
      config = described_class.new
      expect(config.view_mode).to eq(:split)
      expect(config.theme).to eq(:dark)
      expect(config.show_page_numbers).to be true
      expect(config.line_spacing).to eq(:normal)
      expect(config.highlight_quotes).to be true
      expect(config.page_numbering_mode).to eq(:absolute)
    end

    it "loads existing config file" do
      config_data = {
        view_mode: "single",
        theme: "light",
        show_page_numbers: false,
        page_numbering_mode: "dynamic"
      }
      File.write(config_file, JSON.pretty_generate(config_data))

      config = described_class.new
      expect(config.view_mode).to eq(:single)
      expect(config.theme).to eq(:light)
      expect(config.show_page_numbers).to be false
      expect(config.page_numbering_mode).to eq(:dynamic)
    end
  end

  describe "#save" do
    it "saves config to file" do
      config = described_class.new
      config.view_mode = :single
      config.save

      saved_data = JSON.parse(File.read(config_file))
      expect(saved_data["view_mode"]).to eq("single")
    end

    it "creates config directory if it doesn't exist" do
      FileUtils.rm_rf(config_dir)
      config = described_class.new
      config.save

      expect(File.exist?(config_dir)).to be true
    end
  end

  describe "#to_h" do
    it "returns config as hash" do
      config = described_class.new
      hash = config.to_h

      expect(hash).to include(
        view_mode: :split,
        theme: :dark,
        show_page_numbers: true,
        line_spacing: :normal,
        highlight_quotes: true,
        page_numbering_mode: :absolute
      )
    end
  end
end
