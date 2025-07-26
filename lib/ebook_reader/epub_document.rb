# frozen_string_literal: true
require_relative "infrastructure/logger"
require_relative "infrastructure/performance_monitor"

require 'zip'
require 'rexml/document'
require 'tempfile'
require 'fileutils'
require 'cgi'
require_relative 'helpers/html_processor'
require_relative 'helpers/opf_processor'

module EbookReader
  # EPUB document class
  class EPUBDocument
    attr_reader :title, :chapters, :language

    def initialize(path)
      @path = path
      @title = File.basename(path, '.epub').gsub('_', ' ')
      @language = 'en_US'
      @chapters = []
      parse_epub
    end

    def chapter_count
      @chapters.size
    end

    def get_chapter(index)
      return nil if @chapters.empty?

      @chapters[index] if index >= 0 && index < @chapters.size
    end

    private

    def parse_epub
      Infrastructure::Logger.info("Parsing EPUB", path: @path)
      Infrastructure::PerformanceMonitor.time("epub_parsing") do
      Dir.mktmpdir do |tmpdir|
        extract_epub(tmpdir)
        load_epub_content(tmpdir)
      end
      # *** THIS IS THE FIX ***
      # After attempting to parse, if no chapters were loaded for any reason
      # (e.g., missing OPF), ensure a default chapter exists.
      ensure_chapters_exist
    rescue StandardError => e
      create_error_chapter(e)
      end
    end

    def create_error_chapter(error)
      @chapters = [{
        number: '1',
        title: 'Error Loading',
        lines: ["Error: #{error.message}"]
      }]
    end

    def extract_epub(tmpdir)
      Zip::File.open(@path) do |zip|
        zip.each do |entry|
          dest = File.join(tmpdir, entry.name)
          FileUtils.mkdir_p(File.dirname(dest))
          entry.extract(dest) unless File.exist?(dest)
        end
      end
    end

    def load_epub_content(tmpdir)
      opf_path = find_opf_path(tmpdir)
      return unless opf_path

      process_opf(opf_path)
    end

    def find_opf_path(tmpdir)
      container_file = File.join(tmpdir, 'META-INF', 'container.xml')
      return unless File.exist?(container_file)

      container = REXML::Document.new(File.read(container_file))
      rootfile = container.elements['//rootfile']
      return unless rootfile

      opf_path = File.join(tmpdir, rootfile.attributes['full-path'])
      opf_path if File.exist?(opf_path)
    end

    def process_opf(opf_path)
      processor = Helpers::OPFProcessor.new(opf_path)

      # Extract metadata
      metadata = processor.extract_metadata
      @title = metadata[:title] || @title
      @language = metadata[:language] || @language

      # Build manifest and get chapter titles
      manifest = processor.build_manifest_map
      chapter_titles = processor.extract_chapter_titles(manifest)

      # Process spine
      processor.process_spine(manifest, chapter_titles) do |file_path, number, title|
        chapter = load_chapter(file_path, number, title)
        @chapters << chapter if chapter
      end
    end

    def ensure_chapters_exist
      return unless @chapters.empty?

      @chapters << {
        number: '1',
        title: 'Empty Book',
        lines: ['This EPUB appears to be empty.']
      }
    end

    def load_chapter(path, number, title_from_ncx = nil)
      content = read_file_content(path)

      title = title_from_ncx || Helpers::HTMLProcessor.extract_title(content) || "Chapter #{number}"
      text = Helpers::HTMLProcessor.html_to_text(content)
      lines = text.split("\n").reject { |line| line.strip.empty? }

      {
        number: number.to_s,
        title: title,
        lines: lines
      }
    rescue StandardError
      nil
    end

    def read_file_content(path)
      content = File.read(path, encoding: 'UTF-8')
      content = content[1..] if content.start_with?("\uFEFF")
      content
    end
  end
end
