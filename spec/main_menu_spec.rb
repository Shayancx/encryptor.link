require 'spec_helper'

RSpec.describe EbookReader::MainMenu do
  let(:menu) { described_class.new }

  before do
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::Terminal).to receive(:read_key).and_return('q')
    allow(menu).to receive(:loop).and_yield
  end

  describe "#run" do
    it "sets up terminal" do
      expect(EbookReader::Terminal).to receive(:setup)
      menu.run
    end

    it "starts scanner if no cached epubs" do
      scanner = menu.instance_variable_get(:@scanner)
      allow(scanner).to receive(:epubs).and_return([])
      expect(scanner).to receive(:start_scan)
      menu.run
    end
  end

  describe "navigation" do
    it "navigates menu with j/k keys" do
      expect(menu.instance_variable_get(:@selected)).to eq(0)
      menu.send(:handle_menu_input, 'j')
      expect(menu.instance_variable_get(:@selected)).to eq(1)
      menu.send(:handle_menu_input, 'k')
      expect(menu.instance_variable_get(:@selected)).to eq(0)
    end

    it "switches to browse mode on f key" do
      menu.send(:handle_menu_input, 'f')
      expect(menu.instance_variable_get(:@mode)).to eq(:browse)
    end

    it "exits on q key" do
      expect(menu).to receive(:cleanup_and_exit).with(0, '')
      menu.send(:handle_menu_input, 'q')
    end
  end

  describe "browse mode" do
    before do
      menu.instance_variable_set(:@mode, :browse)
      menu.instance_variable_set(:@filtered_epubs, [
        { 'name' => 'Book 1', 'path' => '/book1.epub' }
      ])
    end

    it "opens selected book on enter" do
      allow(File).to receive(:exist?).and_return(true)
      expect(menu).to receive(:open_book).with('/book1.epub')
      menu.send(:handle_browse_input, "\r")
    end

    it "filters books on search" do
      menu.instance_variable_set(:@scanner, double(epubs: [
        { 'name' => 'Book 1', 'path' => '/book1.epub' },
        { 'name' => 'Another', 'path' => '/another.epub' }
      ]))
      
      menu.send(:handle_browse_input, 'b')
      menu.send(:handle_browse_input, 'o')
      
      filtered = menu.instance_variable_get(:@filtered_epubs)
      expect(filtered.size).to eq(1)
      expect(filtered.first['name']).to eq('Book 1')
    end
  end
end
