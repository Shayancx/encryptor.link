# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/ui/browse_screen'

describe EbookReader::Ui::BrowseScreen, fake_fs: true do
  let(:terminal) { double("EbookReader::Terminal", width: 80, height: 24, clear: nil, move_to: nil, print: nil) }
  let(:epub_finder) { double("EbookReader::EpubFinder", epubs: ['/book1.epub', '/book2.epub']) }
  let(:browse_screen) { described_class.new(epub_finder, terminal) }

  describe "#render" do
    it "displays the list of epubs" do
      expect(terminal).to receive(:print).with(/book1.epub/)
      expect(terminal).to receive(:print).with(/book2.epub/)
      browse_screen.render
    end

    it "highlights the selected epub" do
      browse_screen.selected_index = 1
      expect(terminal).to receive(:print).with(a_string_matching(/book2.epub/))
      browse_screen.render
    end
  end

  describe "input handling" do
    it "moves selection down" do
      browse_screen.handle_input("\e[B")
      expect(browse_screen.selected_index).to eq(1)
    end

    it "moves selection up" do
      browse_screen.selected_index = 1
      browse_screen.handle_input("\e[A")
      expect(browse_screen.selected_index).to eq(0)
    end

    it "selects a book on enter" do
      expect(browse_screen.handle_input("\r")).to eq('/book1.epub')
    end

    it "quits on 'q'" do
      expect(browse_screen.handle_input("q")).to eq(:quit)
    end
  end
end
