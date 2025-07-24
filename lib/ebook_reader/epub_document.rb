# frozen_string_literal: true

require 'zip'
require 'rexml/document'
require 'tempfile'
require 'fileutils'
require 'cgi'

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
      Dir.mktmpdir do |tmpdir|
        extract_epub(tmpdir)
        load_epub_content(tmpdir)
      end
    rescue StandardError => e
      @chapters = [{
        number: '1',
        title: 'Error Loading',
        lines: ["Error: #{e.message}"]
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
      container_file = File.join(tmpdir, 'META-INF', 'container.xml')
      return unless File.exist?(container_file)

      container = REXML::Document.new(File.read(container_file))
      rootfile = container.elements['//rootfile']
      return unless rootfile

      opf_path = File.join(tmpdir, rootfile.attributes['full-path'])
      return unless File.exist?(opf_path)

      process_opf(opf_path)
    end

    def process_opf(opf_path)
      opf_dir = File.dirname(opf_path)
      opf = REXML::Document.new(File.read(opf_path))

      # Get metadata
      if (metadata = opf.elements['//metadata'])
        @title = metadata.elements['*[local-name()="title"]']&.text || @title
        if (lang = metadata.elements['*[local-name()="language"]']&.text)
          @language = lang.include?('_') ? lang : "#{lang}_#{lang.upcase}"
        end
      end

      # Build manifest map
      manifest = {}
      opf.elements.each('//manifest/item') do |item|
        id = item.attributes['id']
        href = item.attributes['href']
        manifest[id] = CGI.unescape(href) if id && href
      end

      # Find and parse NCX for chapter titles
      ncx_id = opf.elements['//spine']&.attributes&.[]('toc')
      ncx_href = manifest[ncx_id] if ncx_id
      chapter_titles = {}
      if ncx_href && File.exist?(File.join(opf_dir, ncx_href))
        ncx_path = File.join(opf_dir, ncx_href)
        ncx = REXML::Document.new(File.read(ncx_path))
        ncx.elements.each('//navMap/navPoint/navLabel/text') do |label|
          nav_point = label.parent.parent
          content_src = nav_point.elements['content']&.attributes&.[]('src')
          next unless content_src

          # Normalize src to match manifest href
          key = content_src.split('#').first
          chapter_titles[key] = clean_html(label.text)
        end
      end

      # Process spine in order
      chapter_num = 1
      opf.elements.each('//spine/itemref') do |itemref|
        idref = itemref.attributes['idref']
        next unless idref && manifest[idref]

        href = manifest[idref]
        file_path = File.join(opf_dir, href)
        next unless File.exist?(file_path)

        # Use title from NCX if available, otherwise extract from file
        title = chapter_titles[href]
        chapter = load_chapter(file_path, chapter_num, title)
        if chapter
          @chapters << chapter
          chapter_num += 1
        end
      end

      # Ensure at least one chapter
      return unless @chapters.empty?

      @chapters << {
        number: '1',
        title: 'Empty Book',
        lines: ['This EPUB appears to be empty.']
      }
    end

    def load_chapter(path, number, title_from_ncx = nil)
      content = File.read(path, encoding: 'UTF-8')
      content = content[1..] if content.start_with?("\uFEFF")

      # Use title from NCX if provided, otherwise extract from HTML
      title = title_from_ncx || extract_title(content) || "Chapter #{number}"

      # Convert HTML to text
      text = html_to_text(content)

      # Split into lines (don't wrap yet)
      lines = text.split("\n").reject { |line| line.strip.empty? }

      {
        number: number.to_s,
        title: title,
        lines: lines
      }
    rescue StandardError
      nil
    end

    def extract_title(html)
      if (match = html.match(%r{<title[^>]*>([^<]+)</title>}i))
        clean_html(match[1])
      elsif (match = html.match(%r{<h[1-3][^>]*>([^<]+)</h[1-3]>}i))
        clean_html(match[1])
      end
    end

    def html_to_text(html)
      text = html.dup

      # Remove scripts and styles completely
      text.gsub!(%r{<script[^>]*>.*?</script>}mi, '')
      text.gsub!(%r{<style[^>]*>.*?</style>}mi, '')

      # Convert block elements to line breaks
      text.gsub!(%r{</p>}i, "\n\n")
      text.gsub!(/<p[^>]*>/i, "\n\n")
      text.gsub!(/<br[^>]*>/i, "\n")
      text.gsub!(%r{</h[1-6]>}i, "\n\n")
      text.gsub!(/<h[1-6][^>]*>/i, "\n\n")
      text.gsub!(%r{</div>}i, "\n")
      text.gsub!(/<div[^>]*>/i, "\n")

      # Remove all other tags
      text.gsub!(/<[^>]+>/, '')

      # Decode HTML entities
      text = CGI.unescapeHTML(text)

      # Clean up whitespace
      text.gsub!(/\\r/, '')
      text.gsub!(/\\n{3,}/, "\n\n")
      text.gsub!(/[ \t]+/, ' ')
      text.strip
    end

    def clean_html(text)
      CGI.unescapeHTML(text.strip)
    end
  end
end
