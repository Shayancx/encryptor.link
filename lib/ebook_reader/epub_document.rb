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

    # Parse the EPUB file and populate chapters.
    #
    # The EPUB is first extracted into a temporary directory so the
    # filesystem remains clean. Once extracted we locate the OPF file
    # described in META-INF/container.xml and use that to build the
    # chapter list. Any errors encountered during this process are
    # captured and presented to the user as a single "Error" chapter so
    # the application can continue running.
    def parse_epub
      Infrastructure::Logger.info("Parsing EPUB", path: @path)
      Infrastructure::PerformanceMonitor.time("epub_parsing") do
        Dir.mktmpdir do |tmpdir|
          extract_epub(tmpdir)
          load_epub_content(tmpdir)
        end
        ensure_chapters_exist
      rescue Zip::Error, REXML::ParseException, Errno::ENOENT, StandardError => e
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

    # Extract all files from the EPUB archive into the given temporary
    # directory. Rubyzip changed its API around 2.0 which can cause
    # ArgumentErrors when calling `entry.extract`. To remain compatible
    # with older versions we attempt the standard extraction first and
    # fall back to several alternatives if needed.
    def extract_epub(tmpdir)
      Zip::File.open(@path) do |zip|
        zip.each do |entry|
          # Skip directories
          next if entry.name.end_with?('/')
          
          dest = File.join(tmpdir, entry.name)
          FileUtils.mkdir_p(File.dirname(dest))
          
          # CRITICAL FIX: Handle different rubyzip versions
          if !File.exist?(dest)
            begin
              # First try the standard way
              entry.extract(dest)
            rescue ArgumentError => e
              if e.message.include?("wrong number of arguments")
                # For rubyzip versions that don't accept parameters
                # Use the block form which works in all versions
                zip.extract(entry, dest) { true }
              else
                raise
              end
            rescue => e
              # Ultimate fallback - read and write manually
              File.open(dest, 'wb') do |f|
                f.write(zip.read(entry))
              end
            end
          end
        end
      end
    end

    # After extraction this method finds the OPF file and begins the
    # parsing process that builds our chapter list and metadata.
    def load_epub_content(tmpdir)
      opf_path = find_opf_path(tmpdir)
      return unless opf_path

      process_opf(opf_path)
    end

    # Locate the OPF package file which describes the contents of the
    # EPUB. Its path is defined in META-INF/container.xml as required by
    # the EPUB specification.
    def find_opf_path(tmpdir)
      container_file = File.join(tmpdir, 'META-INF', 'container.xml')
      return unless File.exist?(container_file)

      container = REXML::Document.new(File.read(container_file))
      rootfile = container.elements['//rootfile']
      return unless rootfile

      opf_path = File.join(tmpdir, rootfile.attributes['full-path'])
      opf_path if File.exist?(opf_path)
    end

    # Parse the OPF file using the helper processor. This extracts
    # metadata such as the book title and language, builds a manifest of
    # all items in the EPUB, and walks the spine to determine chapter
    # order. Each referenced HTML file is converted into a chapter
    # structure the reader can display.
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

    # Load a single chapter HTML file and convert it to plain text lines.
    # If an error occurs while reading or parsing the file we simply skip the
    # chapter so the rest of the book can still be viewed. Titles are
    # extracted from the HTML when available or generated automatically.
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
    rescue Errno::ENOENT, REXML::ParseException
      nil
    end

    # Utility method to read a file as UTF-8 while stripping any UTF-8
    # BOM that may be present.
    def read_file_content(path)
      content = File.read(path, encoding: 'UTF-8')
      content = content[1..] if content.start_with?("\uFEFF")
      content
    end
  end
end
