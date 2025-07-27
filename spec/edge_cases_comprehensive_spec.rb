# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Edge Cases Comprehensive" do
  describe 'Input handling edge cases' do
    it 'handles rapid repeated input' do
      reader = instance_double(EbookReader::Reader)
      allow(reader).to receive(:scroll_down)

      command = EbookReader::Commands::ScrollDownCommand.new(reader)
      100.times { command.execute }
    end

    it 'handles invalid UTF-8 in input' do
      menu = EbookReader::MainMenu.new
      invalid_input = "\xFF\xFE"
      expect { menu.send(:searchable_key?, invalid_input) }.not_to raise_error
    end
  end

  describe 'File system edge cases' do
    it 'handles file system errors gracefully' do
      errors = [
        Errno::EACCES,
        Errno::ENOENT,
        Errno::EISDIR,
        Errno::ENOTDIR,
        Errno::EMFILE,
        Errno::ENFILE
      ]

      errors.each do |error_class|
        allow(File).to receive(:read).and_raise(error_class)
        expect { EbookReader::Config.new }.not_to raise_error
      end
    end

    it 'handles concurrent file access' do
      allow(File).to receive(:write).and_raise(Errno::EAGAIN)
      config = EbookReader::Config.new
      expect { config.save }.not_to raise_error
    end
  end

  describe 'Memory management' do
    it 'handles large chapters efficiently' do
      large_chapter = { title: "Large", lines: Array.new(10_000) { |i| "Line #{i}" * 10 } }
      doc = instance_double(EbookReader::EPUBDocument,
                            chapters: [large_chapter],
                            chapter_count: 1,
                            title: "Test",
                            language: "en")

      allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
      allow(doc).to receive(:get_chapter).and_return(large_chapter)

      reader = EbookReader::Reader.new('/test.epub')
      expect { reader.send(:update_page_map, 80, 24) }.not_to raise_error
    end
  end

  describe 'Unicode handling' do
    it 'handles various Unicode characters' do
      test_strings = [
        "English text",
        "中文文本",
        "日本語テキスト",
        "한국어 텍스트",
        "Русский текст",
        "🎨 Emoji 🎭 text 🎪",
        "Mixed 中文 and English"
      ]

      processor = EbookReader::Helpers::HTMLProcessor
      test_strings.each do |str|
        html = "<p>#{str}</p>"
        result = processor.html_to_text(html)
        expect(result).to include(str)
      end
    end
  end

  describe 'Thread safety' do
    it 'handles concurrent scanner operations' do
      scanner = EbookReader::Helpers::EPUBScanner.new

      threads = 5.times.map do
        Thread.new do
          scanner.start_scan
          scanner.process_results
        end
      end

      expect { threads.each(&:join) }.not_to raise_error
    end
  end

  describe 'Performance edge cases' do
    it 'handles performance monitoring overflow' do
      1000.times do |i|
        EbookReader::Infrastructure::PerformanceMonitor.time("op_#{i}") { sleep 0.001 }
      end

      stats = EbookReader::Infrastructure::PerformanceMonitor.stats("op_1")
      expect(stats).not_to be_nil
    end
  end
end
