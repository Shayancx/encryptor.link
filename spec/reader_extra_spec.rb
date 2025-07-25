# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Reader, 'extra' do
  let(:epub_path) { '/book.epub' }
  let(:config) { EbookReader::Config.new }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: 'T',
                    language: 'en',
                    chapter_count: 1,
                    chapters: [{ title: 'Ch', lines: ['line one'] }])
  end

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter).and_return(doc.chapters.first)
    allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
    allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)
  end

  subject(:reader) { described_class.new(epub_path, config) }

  context 'when generating error lines' do
    it 'builds informative lines' do
      lines = reader.send(:build_error_lines, 'oops')
      expect(lines.first).to eq('Failed to load EPUB file:')
      expect(lines).to include('Possible causes:')
    end
  end

  describe '#size_changed?' do
    it 'detects dimension changes' do
      reader.instance_variable_set(:@last_width, 80)
      reader.instance_variable_set(:@last_height, 24)
      expect(reader.send(:size_changed?, 80, 24)).to be false
      expect(reader.send(:size_changed?, 81, 24)).to be true
    end
  end

  describe '#should_highlight_line?' do
    it 'matches keywords when enabled' do
      expect(reader.send(:should_highlight_line?, 'Chinese poets')).to be_truthy
    end

    it 'ignores when disabled' do
      config.highlight_quotes = false
      expect(reader.send(:should_highlight_line?, '"quote"')).to be false
    end
  end

  describe '#calculate_actual_height' do
    it 'returns half height for relaxed spacing' do
      config.line_spacing = :relaxed
      expect(reader.send(:calculate_actual_height, 10)).to eq(5)
    end
  end
end
