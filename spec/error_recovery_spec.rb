# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Error Recovery' do
  describe EbookReader::MainMenu do
    it 'recovers from reader crash' do
      menu = described_class.new
      allow(EbookReader::Terminal).to receive(:setup)
      allow(EbookReader::Terminal).to receive(:cleanup)

      reader = instance_double(EbookReader::Reader)
      allow(EbookReader::Reader).to receive(:new).and_return(reader)
      allow(reader).to receive(:run).and_raise(StandardError.new('Reader crashed'))

      menu.send(:open_book, '/book.epub')

      # Should set error state but not crash
      scanner = menu.instance_variable_get(:@scanner)
      expect(scanner.scan_status).to eq(:error)
    end
  end

  describe EbookReader::BookmarkManager do
    it 'handles file lock errors' do
      allow(File).to receive(:write).and_raise(Errno::EWOULDBLOCK)

      expect { described_class.add('/book.epub', 0, 0, 'test') }.not_to raise_error
    end
  end

  describe EbookReader::EPUBFinder do
    it 'handles interrupted system call' do
      allow(Dir).to receive(:entries).and_raise(Errno::EINTR)

      result = described_class.scan_system(force_refresh: true)
      expect(result).to be_an(Array)
    end
  end
end
