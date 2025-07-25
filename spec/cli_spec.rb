# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/cli'

describe EbookReader::Cli do
  let(:main_menu) { double("EbookReader::MainMenu") }
  let(:config) { double("EbookReader::Config") }

  before do
    allow(EbookReader::Config).to receive(:load).and_return(config)
    allow(EbookReader::MainMenu).to receive(:new).and_return(main_menu)
    allow(main_menu).to receive(:run)
  end

  describe ".run" do
    it "loads the config" do
      expect(EbookReader::Config).to receive(:load)
      described_class.run
    end

    it "creates a new main menu" do
      expect(EbookReader::MainMenu).to receive(:new)
      described_class.run
    end

    it "runs the main menu" do
      expect(main_menu).to receive(:run)
      described_class.run
    end
  end
end
