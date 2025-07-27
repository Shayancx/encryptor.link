# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::MainMenu, 'edge cases' do
  let(:menu) { described_class.new }
  let(:scanner) { menu.instance_variable_get(:@scanner) }

  before do
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::Terminal).to receive(:write)
    allow(menu).to receive(:loop).and_yield
  end

  describe 'search functionality' do
    it 'handles search with special regex characters' do
      scanner.epubs = [
        { 'name' => 'Book (1)', 'path' => '/book1.epub' },
        { 'name' => 'Book [2]', 'path' => '/book2.epub' },
      ]

      menu.instance_variable_set(:@search_query, '(1)')
      menu.send(:filter_books)
      filtered = menu.instance_variable_get(:@filtered_epubs)

      expect(filtered.size).to eq(1)
    end

    it 'handles empty search query after adding characters' do
      menu.instance_variable_set(:@mode, :browse)
      menu.instance_variable_set(:@search_query, 'test')

      4.times { menu.send(:handle_backspace) }

      expect(menu.instance_variable_get(:@search_query)).to eq('')
    end
  end

  describe 'file dialog' do
    it 'allows cancelling with escape key' do
      menu.send(:open_file_dialog)
      menu.send(:handle_open_file_input, "\e")
      expect(menu.instance_variable_get(:@mode)).to eq(:menu)
    end

    it 'handles path with nested quotes' do
      menu.send(:open_file_dialog)
      %("'/path/to/book.epub'").each_char { |ch| menu.send(:handle_open_file_input, ch) }
      expect(menu).to receive(:handle_file_path).with(File.expand_path("'/path/to/book.epub'"))
      menu.send(:handle_open_file_input, "\n")
    end
  end

  describe 'time formatting' do
    it 'handles nil time' do
      expect(menu.send(:time_ago_in_words, nil)).to eq('unknown')
    end

    it 'handles future time' do
      future_time = Time.now + 3600
      result = menu.send(:time_ago_in_words, future_time)
      # Future times show as date format, not "just now"
      expect(result).to match(/\w{3} \d{1,2}/)
    end

    it 'handles time parse errors' do
      invalid_time = Object.new
      expect(menu.send(:time_ago_in_words, invalid_time)).to eq('unknown')
    end

    it 'handles very recent time' do
      recent_time = Time.now - 30
      result = menu.send(:time_ago_in_words, recent_time)
      expect(result).to eq('just now')
    end
  end

  describe 'navigation edge cases' do
    it 'handles navigation with empty epubs list' do
      menu.instance_variable_set(:@mode, :browse)
      menu.instance_variable_set(:@filtered_epubs, [])

      expect { menu.send(:handle_browse_input, 'j') }.not_to raise_error
      expect { menu.send(:handle_browse_input, "\r") }.not_to raise_error
    end
  end
end
