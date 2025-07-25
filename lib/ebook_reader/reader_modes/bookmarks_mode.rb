# frozen_string_literal: true

require_relative 'base_mode'

module EbookReader
  module ReaderModes
    # Bookmark management interface
    class BookmarksMode < BaseMode
      include Concerns::InputHandler

      def initialize(reader)
        super
        @selected = 0
        @bookmarks = reader.send(:bookmarks)
      end

      def draw(height, width)
        draw_header(width)

        if @bookmarks.empty?
          draw_empty_state(height, width)
        else
          draw_bookmark_list(height, width)
        end

        draw_footer(height)
      end

      def handle_input(key)
        return handle_empty_input(key) if @bookmarks.empty?

        if escape_key?(key) || key == 'B'
          reader.switch_mode(:read)
        elsif navigation_key?(key)
          @selected = handle_navigation_keys(key, @selected, @bookmarks.length - 1)
        elsif enter_key?(key)
          jump_to_bookmark
        elsif %w[d D].include?(key)
          delete_bookmark
        end
      end

      private

      def handle_empty_input(key)
        reader.switch_mode(:read) if escape_key?(key) || key == 'B'
      end

      def draw_header(width)
        terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}🔖 Bookmarks#{Terminal::ANSI::RESET}")
        terminal.write(1, [width - 40, 40].max,
                       "#{Terminal::ANSI::DIM}[B/ESC] Back [d] Delete#{Terminal::ANSI::RESET}")
      end

      def draw_empty_state(height, width)
        terminal.write(height / 2, (width - 20) / 2,
                       "#{Terminal::ANSI::DIM}No bookmarks yet#{Terminal::ANSI::RESET}")
      end

      def draw_bookmark_list(height, width)
        list_start = 4
        items_per_page = (height - 6) / 2

        visible_range = calculate_visible_range(items_per_page)

        visible_range.each_with_index do |idx, row_idx|
          bookmark = @bookmarks[idx]
          draw_bookmark_item(bookmark, idx, list_start + (row_idx * 2), width)
        end
      end

      def draw_bookmark_item(bookmark, idx, row, width)
        doc = reader.send(:doc)
        chapter = doc.get_chapter(bookmark['chapter'])
        chapter_title = chapter&.[](:title) || "Chapter #{bookmark['chapter'] + 1}"

        if idx == @selected
          draw_selected_bookmark(row, width, bookmark, chapter_title)
        else
          draw_unselected_bookmark(row, width, bookmark, chapter_title)
        end
      end

      def draw_selected_bookmark(row, width, bookmark, chapter_title)
        terminal.write(row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")

        chapter_text = "Ch. #{bookmark['chapter'] + 1}: #{chapter_title[0, width - 20]}"
        terminal.write(row, 4,
                       "#{Terminal::ANSI::BRIGHT_WHITE}#{chapter_text}#{Terminal::ANSI::RESET}")

        bookmark_text = bookmark['text'][0, width - 8]
        terminal.write(row + 1, 6,
                       "#{Terminal::ANSI::ITALIC}#{Terminal::ANSI::GRAY}#{bookmark_text}#{Terminal::ANSI::RESET}")
      end

      def draw_unselected_bookmark(row, width, bookmark, chapter_title)
        chapter_text = "Ch. #{bookmark['chapter'] + 1}: #{chapter_title[0, width - 20]}"
        terminal.write(row, 4,
                       "#{Terminal::ANSI::WHITE}#{chapter_text}#{Terminal::ANSI::RESET}")

        bookmark_text = bookmark['text'][0, width - 8]
        terminal.write(row + 1, 6,
                       "#{Terminal::ANSI::DIM}#{Terminal::ANSI::GRAY}#{bookmark_text}#{Terminal::ANSI::RESET}")
      end

      def draw_footer(height)
        terminal.write(height - 1, 2,
                       "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Jump • d Delete • B/ESC Back#{Terminal::ANSI::RESET}")
      end

      def calculate_visible_range(items_per_page)
        visible_start = [@selected - (items_per_page / 2), 0].max
        visible_end = [visible_start + items_per_page, @bookmarks.length].min
        visible_start...visible_end
      end

      def jump_to_bookmark
        bookmark = @bookmarks[@selected]
        return unless bookmark

        reader.send(:jump_to_bookmark)
      end

      def delete_bookmark
        bookmark = @bookmarks[@selected]
        return unless bookmark

        reader.send(:delete_selected_bookmark)
        @bookmarks = reader.send(:bookmarks)
        @selected = [@selected, @bookmarks.length - 1].min if @bookmarks.any?
      end
    end
  end
end
