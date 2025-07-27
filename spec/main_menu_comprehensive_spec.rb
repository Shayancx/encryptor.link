# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::MainMenu, 'comprehensive' do
  let(:menu) { described_class.new }
  let(:scanner) { menu.instance_variable_get(:@scanner) }

  before do
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::Terminal).to receive(:write)
    allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
    allow(menu).to receive(:loop).and_yield
  end

  describe 'navigation edge cases' do
    it 'handles arrow key variations' do
      menu.instance_variable_set(:@mode, :browse)
      menu.instance_variable_set(:@filtered_epubs, [
                                   { 'name' => 'Book 1' },
                                   { 'name' => 'Book 2' },
                                 ])

      # Test OA/OB variants (some terminals)
      menu.send(:handle_browse_input, "\eOA")
      expect(menu.instance_variable_get(:@browse_selected)).to eq(0)

      menu.send(:handle_browse_input, "\eOB")
      expect(menu.instance_variable_get(:@browse_selected)).to eq(1)
    end

    it 'handles search with empty scanner epubs' do
      menu.instance_variable_set(:@mode, :browse)
      scanner.epubs = []
      menu.instance_variable_set(:@search_query, '')

      menu.send(:add_to_search, 'a')
      expect(menu.instance_variable_get(:@search_query)).to eq('a')
      expect(menu.instance_variable_get(:@filtered_epubs)).to eq([])
    end
  end

  describe 'recent files handling' do
    it 'handles recent files with missing paths' do
      allow(EbookReader::RecentFiles).to receive(:load).and_return([
                                                                     { 'path' => '/exists.epub', 'name' => 'Exists' },
                                                                     { 'path' => nil, 'name' => 'No Path' },
                                                                     { 'name' => 'Missing Path Key' },
                                                                   ])
      allow(File).to receive(:exist?).with('/exists.epub').and_return(true)

      recent = menu.send(:load_recent_books)
      expect(recent.size).to eq(1)
      expect(recent.first['name']).to eq('Exists')
    end
  end

  describe 'file dialog edge cases' do
    it 'handles interrupt during file dialog' do
      allow(menu).to receive(:gets).and_raise(Interrupt)
      expect { menu.send(:open_file_dialog) }.not_to raise_error
    end

    it 'sanitizes various quote styles' do
      expect(menu.send(:sanitize_input_path, %("path"))).to eq(File.expand_path('path'))
      expect(menu.send(:sanitize_input_path, "'path'")).to eq(File.expand_path('path'))
      expect(menu.send(:sanitize_input_path, %("'nested'"))).to eq(File.expand_path("'nested'"))
    end

    it 'expands home directory' do
      input = '~/book.epub'
      expanded = File.expand_path('~/book.epub')
      expect(menu.send(:sanitize_input_path, input)).to eq(expanded)
    end
  end

  describe 'error handling' do
    it 'handles reader initialization errors' do
      menu.instance_variable_set(:@mode, :browse)
      allow(File).to receive(:exist?).and_return(true)
      allow(EbookReader::Reader).to receive(:new).and_raise(StandardError.new('Init failed'))

      menu.send(:open_book, '/error.epub')
      expect(scanner.scan_status).to eq(:error)
      expect(scanner.scan_message).to include('Failed')
    end
  end
end
