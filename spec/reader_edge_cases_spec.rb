# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Reader, 'edge cases' do
  let(:epub_path) { '/edge.epub' }
  let(:config) { EbookReader::Config.new }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    title: 'Edge Case Book',
                    language: 'en',
                    chapter_count: 1,
                    chapters: [{ title: 'Chapter', lines: ['Line 1'] }])
  end
  let(:reader) { described_class.new(epub_path, config) }

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter).and_return(doc.chapters.first)
    allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
    allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)
    allow(EbookReader::ProgressManager).to receive(:save)
    allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
  end

  describe 'page calculations' do
    it 'handles zero height' do
      allow(EbookReader::Terminal).to receive(:size).and_return([0, 80])
      expect { reader.send(:update_page_map, 80, 0) }.not_to raise_error
    end

    it 'handles zero width' do
      allow(EbookReader::Terminal).to receive(:size).and_return([24, 0])
      expect { reader.send(:update_page_map, 0, 24) }.not_to raise_error
    end

    it 'handles very small terminal' do
      allow(EbookReader::Terminal).to receive(:size).and_return([5, 20])
      expect { reader.send(:update_page_map, 20, 5) }.not_to raise_error
    end
  end

  describe 'bookmark edge cases' do
    it 'handles adding bookmark with nil chapter' do
      allow(doc).to receive(:get_chapter).and_return(nil)
      expect { reader.send(:add_bookmark) }.not_to raise_error
    end

    it 'handles bookmark with empty lines' do
      allow(doc).to receive(:get_chapter).and_return({ title: 'Empty', lines: [] })
      expect { reader.send(:add_bookmark) }.not_to raise_error
    end

    it 'handles bookmark text extraction with out of bounds offset' do
      reader.instance_variable_set(:@single_page, 1000)
      expect { reader.send(:add_bookmark) }.not_to raise_error
    end
  end

  describe 'navigation edge cases' do
    it 'handles navigation with nil chapter' do
      allow(doc).to receive(:get_chapter).and_return(nil)
      expect { reader.send(:handle_navigation_input, 'j') }.not_to raise_error
    end

    it 'handles prev_page at chapter boundary' do
      reader.instance_variable_set(:@current_chapter, 1)
      reader.instance_variable_set(:@single_page, 0)
      allow(doc).to receive(:chapter_count).and_return(2)

      reader.send(:prev_page, 10)
      expect(reader.instance_variable_get(:@current_chapter)).to eq(0)
    end
  end

  describe 'progress edge cases' do
    it 'handles corrupted progress data' do
      allow(EbookReader::ProgressManager).to receive(:load).and_return({
                                                                         'chapter' => 999,
                                                                         'line_offset' => -1,
                                                                       })

      reader = described_class.new(epub_path, config)
      expect(reader.instance_variable_get(:@current_chapter)).to eq(0)
    end
  end

  describe 'rendering edge cases' do
    it 'handles nil lines in chapter' do
      allow(doc).to receive(:get_chapter).and_return({ title: 'Nil', lines: nil })
      expect { reader.send(:draw_single_screen, 24, 80) }.not_to raise_error
    end

    it 'handles very long chapter title' do
      long_title = 'A' * 200
      allow(doc).to receive(:get_chapter).and_return({ title: long_title, lines: ['Test'] })
      expect { reader.send(:draw_split_screen, 24, 80) }.not_to raise_error
    end
  end
end
