# frozen_string_literal: true

module EbookReader
  module UI
    # Handles rendering for Reader
    class ReaderRenderer
      include Terminal::ANSI

      def initialize(config)
        @config = config
      end

      def render_header(doc, width, view_mode, mode)
        if view_mode == :single && mode == :read
          title_text = doc.title
          Terminal.write(1, 2, WHITE + title_text[0, width - 4] + RESET)
        else
          title_text = 'Simple Novel Reader'
          Terminal.write(1, 1, WHITE + title_text + RESET)
          right_text = 'q:Quit ?:Help t:ToC B:Bookmarks'
          Terminal.write(1, [width - right_text.length + 1, 1].max,
                         WHITE + right_text + RESET)
        end
      end

      def render_footer(height, width, doc, chapter, pages, view_mode, mode, line_spacing, bookmarks)
        if view_mode == :single && mode == :read
          render_single_view_footer(height, width, pages)
        else
          render_split_view_footer(height, width, doc, chapter, view_mode, line_spacing, bookmarks)
        end
      end

      private

      def render_single_view_footer(height, _width, pages)
        return unless @config.show_page_numbers && pages[:total].positive?

        page_text = "#{pages[:current]} / #{pages[:total]}"
        Terminal.write(height, 2, DIM + GRAY + page_text + RESET)
      end

      def render_split_view_footer(height, width, doc, chapter, view_mode, line_spacing, bookmarks)
        footer1 = [height - 1, 3].max

        left_prog = "[#{chapter + 1}/#{doc.chapter_count}]"
        Terminal.write(footer1, 1, BLUE + left_prog + RESET)

        mode_text = view_mode == :split ? '[SPLIT]' : '[SINGLE]'
        Terminal.write(footer1, [(width / 2) - 10, 20].max, YELLOW + mode_text + RESET)

        right_prog = "L#{line_spacing.to_s[0]} B#{bookmarks.count}"
        Terminal.write(footer1, [width - right_prog.length - 1, 40].max,
                       BLUE + right_prog + RESET)

        render_footer_line2(height, width, doc) if height > 3
      end

      def render_footer_line2(height, width, doc)
        Terminal.write(height, 1, WHITE + "[#{doc.title[0, width - 15]}]" + RESET)
        Terminal.write(height, [width - 10, 50].max,
                       WHITE + "[#{doc.language}]" + RESET)
      end
    end
  end
end
