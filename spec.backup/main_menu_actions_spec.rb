# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::MainMenu, "actions" do
  let(:menu) { described_class.new }
  let(:scanner) { menu.instance_variable_get(:@scanner) }
  let(:config) { menu.instance_variable_get(:@config) }
  let(:reader) { instance_double(EbookReader::Reader, run: true) }

  before do
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::Terminal).to receive(:read_key).and_return('q')
    allow(menu).to receive(:loop).and_yield
    allow(EbookReader::Reader).to receive(:new).and_return(reader)
    allow(File).to receive(:exist?).and_return(true)
  end

  context 'when selecting menu items' do
    it 'handles "Find Book"' do
      menu.instance_variable_set(:@selected, 0)
      menu.send(:handle_menu_selection)
      expect(menu.instance_variable_get(:@mode)).to eq(:browse)
    end

    it 'handles "Recent"' do
      menu.instance_variable_set(:@selected, 1)
      menu.send(:handle_menu_selection)
      expect(menu.instance_variable_get(:@mode)).to eq(:recent)
    end

    it 'handles "Open File"' do
      menu.instance_variable_set(:@selected, 2)
      expect(menu).to receive(:open_file_dialog)
      menu.send(:handle_menu_selection)
    end

    it 'handles "Settings"' do
      menu.instance_variable_set(:@selected, 3)
      menu.send(:handle_menu_selection)
      expect(menu.instance_variable_get(:@mode)).to eq(:settings)
    end

    it 'handles "Quit"' do
      menu.instance_variable_set(:@selected, 4)
      expect(menu).to receive(:cleanup_and_exit).with(0, '')
      menu.send(:handle_menu_selection)
    end
  end

  context 'when in browse mode' do
    before do
      menu.instance_variable_set(:@mode, :browse)
      allow(scanner).to receive(:epubs).and_return([
                                                     { 'name' => 'A Book', 'path' => '/book_a.epub' },
                                                     { 'name' => 'B Book', 'path' => '/book_b.epub' }
                                                   ])
      menu.send(:filter_books)
    end

    it 'filters books based on search query' do
      menu.send(:add_to_search, 'a')
      expect(menu.instance_variable_get(:@filtered_epubs).size).to eq(1)
      expect(menu.instance_variable_get(:@filtered_epubs).first['name']).to eq('A Book')
    end

    it 'handles backspace in search query' do
      menu.send(:add_to_search, 'a')
      menu.send(:handle_backspace)
      expect(menu.instance_variable_get(:@search_query)).to eq('')
      expect(menu.instance_variable_get(:@filtered_epubs).size).to eq(2)
    end

    it 'refreshes the scan' do
      expect(EbookReader::EPUBFinder).to receive(:clear_cache)
      expect(scanner).to receive(:start_scan).with(force: true)
      menu.send(:refresh_scan)
    end
  end

  context 'when in settings mode' do
    before do
      menu.instance_variable_set(:@mode, :settings)
      allow(config).to receive(:save)
    end

    it 'toggles view mode' do
      expect { menu.send(:handle_setting_change, '1') }.to(change { config.view_mode })
    end

    it 'toggles page numbers' do
      expect { menu.send(:handle_setting_change, '2') }.to(change { config.show_page_numbers })
    end

    it 'cycles line spacing' do
      expect { menu.send(:handle_setting_change, '3') }.to(change { config.line_spacing })
    end

    it 'toggles highlight quotes' do
      expect { menu.send(:handle_setting_change, '4') }.to(change { config.highlight_quotes })
    end

    it 'clears the cache' do
      expect(EbookReader::EPUBFinder).to receive(:clear_cache)
      menu.send(:handle_setting_change, '5')
      expect(scanner.scan_message).to include("Cache cleared")
    end
  end

  context 'when opening a book' do
    it 'opens a reader for a valid path' do
      expect(EbookReader::RecentFiles).to receive(:add).with('/valid.epub')
      expect(EbookReader::Reader).to receive(:new).with('/valid.epub', config).and_return(reader)
      expect(reader).to receive(:run)
      menu.send(:open_book, '/valid.epub')
    end

    it 'handles a non-existent file' do
      allow(File).to receive(:exist?).with('/invalid.epub').and_return(false)
      menu.send(:open_book, '/invalid.epub')
      expect(scanner.scan_status).to eq(:error)
      expect(scanner.scan_message).to eq('File not found')
    end
  end
end
