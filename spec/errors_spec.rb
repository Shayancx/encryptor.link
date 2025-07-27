# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Error Classes' do
  describe EbookReader::EPUBParseError do
    it 'includes file path in message' do
      error = described_class.new('Invalid format', '/path/to/book.epub')
      expect(error.message).to include('/path/to/book.epub')
      expect(error.message).to include('Invalid format')
      expect(error.file_path).to eq('/path/to/book.epub')
    end
  end

  describe EbookReader::FileNotFoundError do
    it 'creates proper error message' do
      error = described_class.new('/missing/file.epub')
      expect(error.message).to include('File not found')
      expect(error.message).to include('/missing/file.epub')
      expect(error.file_path).to eq('/missing/file.epub')
    end
  end

  describe EbookReader::TerminalSizeError do
    it 'includes size requirements in message' do
      error = described_class.new(30, 8)
      expect(error.message).to include('30x8')
      expect(error.message).to include('40x10') # minimum size
    end
  end

  describe EbookReader::InvalidStateError do
    it 'includes state information' do
      state = { chapter: -1, page: 0 }
      error = described_class.new('Chapter out of bounds', state)
      expect(error.message).to include('Chapter out of bounds')
      expect(error.state).to eq(state)
    end
  end

  describe EbookReader::NavigationError do
    it 'includes direction and reason' do
      error = described_class.new('forward', 'at end of book')
      expect(error.message).to include('Cannot navigate forward')
      expect(error.message).to include('at end of book')
      expect(error.direction).to eq('forward')
      expect(error.reason).to eq('at end of book')
    end
  end

  describe EbookReader::BookmarkError do
    it 'includes operation details' do
      error = described_class.new('add', 'file is read-only')
      expect(error.message).to include('Bookmark add failed')
      expect(error.message).to include('file is read-only')
      expect(error.operation).to eq('add')
    end
  end

  describe EbookReader::RenderError do
    it 'includes component information' do
      error = described_class.new('HeaderRenderer', 'invalid state')
      expect(error.message).to include('Rendering failed in HeaderRenderer')
      expect(error.message).to include('invalid state')
      expect(error.component).to eq('HeaderRenderer')
    end
  end
end
