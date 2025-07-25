# frozen_string_literal: true

require 'rexml/document'
require 'cgi'

module EbookReader
  module Helpers
    # Processes OPF files
    class OPFProcessor
      def initialize(opf_path)
        @opf_path = opf_path
        @opf_dir = File.dirname(opf_path)
        @opf = REXML::Document.new(File.read(opf_path))
      end

      def extract_metadata
        metadata = {}
        if (meta_elem = @opf.elements['//metadata'])
          metadata[:title] = meta_elem.elements['*[local-name()="title"]']&.text
          if (lang = meta_elem.elements['*[local-name()="language"]']&.text)
            metadata[:language] = lang.include?('_') ? lang : "#{lang}_#{lang.upcase}"
          end
        end
        metadata
      end

      def build_manifest_map
        manifest = {}
        @opf.elements.each('//manifest/item') do |item|
          id = item.attributes['id']
          href = item.attributes['href']
          manifest[id] = CGI.unescape(href) if id && href
        end
        manifest
      end

      def extract_chapter_titles(manifest)
        ncx_id = @opf.elements['//spine']&.attributes&.[]('toc')
        ncx_href = manifest[ncx_id] if ncx_id
        chapter_titles = {}

        if ncx_href && File.exist?(File.join(@opf_dir, ncx_href))
          ncx_path = File.join(@opf_dir, ncx_href)
          ncx = REXML::Document.new(File.read(ncx_path))
          ncx.elements.each('//navMap/navPoint/navLabel/text') do |label|
            nav_point = label.parent.parent
            content_src = nav_point.elements['content']&.attributes&.[]('src')
            next unless content_src

            key = content_src.split('#').first
            chapter_titles[key] = HTMLProcessor.clean_html(label.text)
          end
        end
        chapter_titles
      end

      def process_spine(manifest, chapter_titles, &block)
        chapter_num = 1
        @opf.elements.each('//spine/itemref') do |itemref|
          idref = itemref.attributes['idref']
          next unless idref && manifest[idref]

          href = manifest[idref]
          file_path = File.join(@opf_dir, href)
          next unless File.exist?(file_path)

          title = chapter_titles[href]
          block.call(file_path, chapter_num, title)
          chapter_num += 1
        end
      end
    end
  end
end
