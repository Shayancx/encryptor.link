# frozen_string_literal: true

module EbookReader
  module Concerns
    # Rendering helpers for the bookmarks screen
    module BookmarksUI
      include Constants::UIConstants

      def draw_bookmarks_screen(height, width)
        draw_bookmarks_header(width)

        if @bookmarks.empty?
          draw_empty_bookmarks(height, width)
        else
          draw_bookmarks_list(height, width)
        end

        draw_bookmarks_footer(height)
      end

      def draw_bookmarks_header(width)
        Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}🔖 Bookmarks#{Terminal::ANSI::RESET}")
        Terminal.write(1, [width - 40, 40].max,
                       "#{Terminal::ANSI::DIM}[B/ESC] Back [d] Delete#{Terminal::ANSI::RESET}")
      end

      def draw_empty_bookmarks(height, width)
        Terminal.write(height / 2, (width - MIN_COLUMN_WIDTH) / 2,
                       "#{Terminal::ANSI::DIM}No bookmarks yet.#{Terminal::ANSI::RESET}")
        Terminal.write((height / 2) + 1, (width - 30) / 2,
                       "#{Terminal::ANSI::DIM}Press 'b' while reading to add one.#{Terminal::ANSI::RESET}")
      end

      def draw_bookmarks_list(height, width)
        list_start = 4
        list_height = (height - 6) / 2
        visible_range = calculate_bookmark_visible_range(list_height)

        draw_bookmark_items(visible_range, list_start, width)
      end

      def calculate_bookmark_visible_range(list_height)
        visible_start = [@bookmark_selected - (list_height / 2), 0].max
        visible_end = [visible_start + list_height, @bookmarks.length].min
        visible_start...visible_end
      end

      def draw_bookmark_items(range, list_start, width)
        range.each_with_index do |idx, row_idx|
          bookmark = @bookmarks[idx]
          chapter_title = @doc.get_chapter(bookmark.chapter_index)&.title || "Chapter #{bookmark.chapter_index + 1}"

          draw_bookmark_item(bookmark, chapter_title, idx, list_start + (row_idx * 2), width)
        end
      end

      def draw_bookmark_item(bookmark, chapter_title, idx, row, width)
        line1 = "Ch. #{bookmark.chapter_index + 1}: #{chapter_title}"
        line2 = "  > #{bookmark.text_snippet}"

        if idx == @bookmark_selected
          draw_selected_bookmark_item(row, width, line1, line2)
        else
          draw_unselected_bookmark_item(row, width, line1, line2)
        end
      end

      def draw_selected_bookmark_item(row, width, line1, line2)
        Terminal.write(row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
        Terminal.write(row, 4, Terminal::ANSI::BRIGHT_WHITE + line1[0, width - 6] + Terminal::ANSI::RESET)
        Terminal.write(row + 1, 4,
                       Terminal::ANSI::ITALIC + Terminal::ANSI::GRAY + line2[0, width - 6] + Terminal::ANSI::RESET)
      end

      def draw_unselected_bookmark_item(row, width, line1, line2)
        Terminal.write(row, 4, Terminal::ANSI::WHITE + line1[0, width - 6] + Terminal::ANSI::RESET)
        Terminal.write(row + 1, 4,
                       Terminal::ANSI::DIM + Terminal::ANSI::GRAY + line2[0, width - 6] + Terminal::ANSI::RESET)
      end

      def draw_bookmarks_footer(height)
        Terminal.write(height - 1, 2,
                       "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Jump • d Delete • B/ESC Back#{Terminal::ANSI::RESET}")
      end
    end
  end
end
