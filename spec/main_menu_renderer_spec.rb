# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/ui/main_menu_renderer'

describe EbookReader::Ui::MainMenuRenderer do
  let(:terminal) { double("EbookReader::Terminal", width: 80, height: 24) }
  let(:main_menu) { double("EbookReader::MainMenu", options: ["Open Book", "Recent Files", "Exit"], selected_index: 0) }
  let(:renderer) { described_class.new(main_menu, terminal) }

  before do
    allow(terminal).to receive(:clear)
    allow(terminal).to receive(:move_to)
    allow(terminal).to receive(:print)
  end

  describe "#render" do
    it "clears the terminal" do
      expect(terminal).to receive(:clear)
      renderer.render
    end

    it "prints the title" do
      expect(terminal).to receive(:print).with(/Ebook Reader/)
      renderer.render
    end

    it "prints the menu options" do
      expect(terminal).to receive(:print).with(/Open Book/)
      expect(terminal).to receive(:print).with(/Recent Files/)
      expect(terminal).to receive(:print).with(/Exit/)
      renderer.render
    end

    it "highlights the selected option" do
      expect(terminal).to receive(:print).with(/\e\[7mOpen Book\e\[27m/)
      renderer.render
    end
  end
end
