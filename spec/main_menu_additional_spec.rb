# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::MainMenu do
  let(:menu) { described_class.new }

  before do
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::Terminal).to receive(:setup)
  end

  describe '#time_ago_in_words' do
    it 'formats recent times across ranges' do
      expect(menu.send(:time_ago_in_words, Time.now - 30)).to eq('just now')
      expect(menu.send(:time_ago_in_words, Time.now - 120)).to eq('2m ago')
      expect(menu.send(:time_ago_in_words, Time.now - 7200)).to eq('2h ago')
      expect(menu.send(:time_ago_in_words, Time.now - 172_800)).to eq('2d ago')
      date_text = (Time.now - 3_000_000).strftime('%b %d')
      expect(menu.send(:time_ago_in_words, Time.now - 3_000_000)).to eq(date_text)
    end
  end

  describe '#open_file_dialog' do
    it 'switches to open file mode' do
      menu.send(:open_file_dialog)
      expect(menu.instance_variable_get(:@mode)).to eq(:open_file)
      expect(menu.instance_variable_get(:@file_input)).to eq('')
    end

    it 'passes sanitized path on enter' do
      menu.send(:open_file_dialog)
      '"/path/book.epub"'.each_char { |ch| menu.send(:handle_open_file_input, ch) }
      expect(menu).to receive(:handle_file_path).with(File.expand_path('/path/book.epub'))
      menu.send(:handle_open_file_input, "\n")
    end
  end

  describe '#filter_by_query and #open_selected_book' do
    it 'filters epubs by search query' do
      menu.instance_variable_set(:@scanner, double(epubs: [
                                                     { 'name' => 'Alpha', 'path' => '/a.epub' },
                                                     { 'name' => 'Beta', 'path' => '/b.epub' },
                                                   ]))
      menu.instance_variable_set(:@search_query, 'beta')
      result = menu.send(:filter_by_query)
      expect(result.map { |b| b['name'] }).to eq(['Beta'])
    end

    it 'opens selected book when file exists' do
      menu.instance_variable_set(:@filtered_epubs, [{ 'path' => '/good.epub' }])
      menu.instance_variable_set(:@browse_selected, 0)
      allow(File).to receive(:exist?).with('/good.epub').and_return(true)
      expect(menu).to receive(:open_book).with('/good.epub')
      menu.send(:open_selected_book)
    end

    it 'sets error when selected file missing' do
      scanner = menu.instance_variable_get(:@scanner)
      menu.instance_variable_set(:@filtered_epubs, [{ 'path' => '/missing.epub' }])
      menu.instance_variable_set(:@browse_selected, 0)
      allow(File).to receive(:exist?).with('/missing.epub').and_return(false)
      menu.send(:open_selected_book)
      expect(scanner.scan_status).to eq(:error)
      expect(scanner.scan_message).to eq('File not found')
    end
  end
end
