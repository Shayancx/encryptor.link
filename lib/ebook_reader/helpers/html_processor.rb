# frozen_string_literal: true

require 'cgi'

module EbookReader
  module Helpers
    # Processes HTML content
    class HTMLProcessor
      def self.extract_title(html)
        match = html.match(%r{<title[^>]*>([^<]+)</title>}i) ||
                html.match(%r{<h[1-3][^>]*>([^<]+)</h[1-3]>}i)
        clean_html(match[1]) if match
      end

      def self.html_to_text(html)
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
        text.gsub!("\r", '')
        text.gsub!(/\n{3,}/, "\n\n")
        text.gsub!(/[ \t]+/, ' ')
        text.strip
      end

      def self.clean_html(text)
        CGI.unescapeHTML(text.strip)
      end
    end
  end
end
