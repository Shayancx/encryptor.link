# frozen_string_literal: true

module EbookReader
  module UI
    # Handles browse screen rendering
    class BrowseScreen
      include Terminal::ANSI

      def render_header(width)
        Terminal.write(1, 2, "#{BRIGHT_CYAN}📚 Browse Books#{RESET}")
        Terminal.write(1, [width - 30, 40].max, "#{DIM}[r] Refresh [ESC] Back#{RESET}")
      end

      def render_search_bar(search_query)
        Terminal.write(3, 2, "#{WHITE}Search: #{RESET}")
        Terminal.write(3, 10, "#{BRIGHT_WHITE}#{search_query}_#{RESET}")
      end

      def render_status(scan_status, scan_message)
        status_text = case scan_status
                      when :scanning
                        "#{YELLOW}⟳ #{scan_message}#{RESET}"
                      when :error
                        "#{RED}✗ #{scan_message}#{RESET}"
                      when :done
                        "#{GREEN}✓ #{scan_message}#{RESET}"
                      else
                        ''
                      end
        Terminal.write(4, 2, status_text) unless status_text.empty?
      end

      def render_empty_state(height, width, scan_status, epubs_empty)
        if scan_status == :scanning
          render_scanning_message(height, width)
        elsif epubs_empty
          render_no_files_message(height, width)
        else
          render_no_matches_message(height, width)
        end
      end

      private

      def render_scanning_message(height, width)
        Terminal.write(height / 2, [(width - 30) / 2, 1].max,
                       "#{YELLOW}⟳ Scanning for books...#{RESET}")
        Terminal.write(height / 2 + 2, [(width - 40) / 2, 1].max,
                       "#{DIM}This may take a moment on first run#{RESET}")
      end

      def render_no_files_message(height, width)
        Terminal.write(height / 2, [(width - 30) / 2, 1].max,
                       "#{DIM}No EPUB files found#{RESET}")
        Terminal.write(height / 2 + 2, [(width - 35) / 2, 1].max,
                       "#{DIM}Press [r] to refresh scan#{RESET}")
      end

      def render_no_matches_message(height, width)
        Terminal.write(height / 2, [(width - 25) / 2, 1].max,
                       "#{DIM}No matching books#{RESET}")
      end
    end
  end
end
