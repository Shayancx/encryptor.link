# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::MainMenu, 'recent input' do
  let(:menu) { described_class.new }
  let(:scanner) { menu.instance_variable_get(:@scanner) }

  before do
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
  end

  it 'opens recent book even when selection is out of range' do
    allow(EbookReader::RecentFiles).to receive(:load).and_return([
                                                                   { 'path' => '/book.epub', 'name' => 'Book',
                                                                     'accessed' => Time.now.iso8601 },
                                                                 ])
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/book.epub').and_return(true)
    menu.instance_variable_set(:@browse_selected, 5)

    expect(menu).to receive(:open_book).with('/book.epub')
    menu.send(:handle_recent_input, "\r")
  end

  it 'sets error when recent file is missing' do
    allow(EbookReader::RecentFiles).to receive(:load).and_return([
                                                                   { 'path' => '/missing.epub', 'name' => 'Missing',
                                                                     'accessed' => Time.now.iso8601 },
                                                                 ])
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/missing.epub').and_return(false)
    menu.instance_variable_set(:@browse_selected, 0)

    menu.send(:handle_recent_input, "\r")
    expect(scanner.scan_status).to eq(:error)
    expect(scanner.scan_message).to eq('File not found')
  end
end
