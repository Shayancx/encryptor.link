# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/config'

describe EbookReader::Config, fake_fs: true do
  let(:config_dir) { EbookReader::Constants::CONFIG_DIR }
  let(:config_file) { EbookReader::Constants::CONFIG_FILE }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  describe ".load" do
    it "loads the config file if it exists" do
      config_data = { "font_size" => 12 }
      File.write(config_file, config_data.to_yaml)
      config = described_class.load
      expect(config.font_size).to eq(12)
    end

    it "returns a default config if the file does not exist" do
      config = described_class.load
      expect(config.font_size).to eq(10) # default value
    end
  end

  describe "#save" do
    it "saves the config to a file" do
      config = described_class.new
      config.font_size = 14
      config.save
      loaded_config = YAML.load_file(config_file)
      expect(loaded_config["font_size"]).to eq(14)
    end
  end

  describe "attributes" do
    it "allows getting and setting attributes" do
      config = described_class.new
      config.font_size = 16
      expect(config.font_size).to eq(16)
    end

    it "responds to attribute keys" do
      config = described_class.new
      expect(config).to respond_to(:font_size)
    end
  end
end
