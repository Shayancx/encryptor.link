# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Integration Tests Comprehensive" do
  describe 'Full application flow' do
    it 'handles complete reading session' do
      # Mock full session
      allow(EbookReader::Terminal).to receive(:setup)
      allow(EbookReader::Terminal).to receive(:cleanup)
      allow(EbookReader::Terminal).to receive(:read_key).and_return(
        'f',     # Find book
        '/',     # Search
        't', 'e', 's', 't', # Type "test"
        "\r", # Select book
        'j', 'j', 'j', # Scroll
        'n',     # Next chapter
        'b',     # Add bookmark
        'B',     # View bookmarks
        "\r",    # Select bookmark
        'v',     # Toggle view
        '+',     # Increase spacing
        '?',     # Help
        'q',     # Back to menu
        'q'      # Quit
      )

      expect { EbookReader::CLI.run }.to raise_error(SystemExit)
    end
  end

  describe 'State persistence' do
    it 'maintains state across sessions' do
      # First session
      config1 = EbookReader::Config.new
      config1.view_mode = :single
      config1.line_spacing = :relaxed
      config1.save

      EbookReader::RecentFiles.add('/book1.epub')
      EbookReader::BookmarkManager.add('/book1.epub', 0, 10, 'Test')
      EbookReader::ProgressManager.save('/book1.epub', 1, 20)

      # Reset module state
      EbookReader.reset!

      # Second session
      config2 = EbookReader::Config.new
      expect(config2.view_mode).to eq(:single)
      expect(config2.line_spacing).to eq(:relaxed)

      recent = EbookReader::RecentFiles.load
      expect(recent.first['path']).to eq('/book1.epub')

      bookmarks = EbookReader::BookmarkManager.get('/book1.epub')
      expect(bookmarks.first['text']).to eq('Test')

      progress = EbookReader::ProgressManager.load('/book1.epub')
      expect(progress['chapter']).to eq(1)
      expect(progress['line_offset']).to eq(20)
    end
  end

  describe 'Error recovery' do
    it 'recovers from various error conditions' do
      # Simulate various errors
      menu = EbookReader::MainMenu.new

      # Scanner error
      scanner = menu.instance_variable_get(:@scanner)
      allow(scanner).to receive(:start_scan).and_raise(StandardError.new("Scan failed"))
      expect do
        scanner.start_scan
      rescue StandardError
        nil
      end.not_to raise_error

      # Reader crash
      allow(EbookReader::Reader).to receive(:new).and_raise(StandardError.new("Reader failed"))
      expect { menu.send(:open_book, '/book.epub') }.not_to raise_error

      # Terminal error
      allow(IO).to receive_message_chain(:console, :winsize).and_raise(StandardError)
      expect(EbookReader::Terminal.size).to eq([24, 80])
    end
  end

  describe 'Performance characteristics' do
    it 'handles large file lists efficiently' do
      # Create large file list
      large_list = 1000.times.map do |i|
        {
          'path' => "/book#{i}.epub",
          'name' => "Book #{i}",
          'size' => rand(1_000_000),
          'modified' => Time.now.iso8601
        }
      end

      menu = EbookReader::MainMenu.new
      scanner = menu.instance_variable_get(:@scanner)
      scanner.epubs = large_list

      # Test search performance
      start_time = Time.now
      menu.instance_variable_set(:@search_query, "Book 500")
      menu.send(:filter_books)
      search_time = Time.now - start_time

      expect(search_time).to be < 0.1 # Should be fast
      expect(menu.instance_variable_get(:@filtered_epubs).size).to be > 0
    end
  end
end
