# frozen_string_literal: true

require_relative 'base_mode'

module EbookReader
  module ReaderModes
    # Table of Contents navigation
    class TocMode < BaseMode
      include Concerns::InputHandler

      def initialize(reader)
        super
        @selected = reader.current_chapter
      end

      def draw(height, width)
        draw_header(width)
        draw_chapter_list(height, width)
        draw_footer(height)
      end

      def handle_input(key)
        if escape_key?(key) || %w[t T].include?(key)
          reader.switch_mode(:read)
        elsif navigation_key?(key)
          max_index = reader.send(:doc).chapter_count - 1
          @selected = handle_navigation_keys(key, @selected, max_index)
        elsif enter_key?(key)
          reader.send(:jump_to_chapter, @selected)
          reader.switch_mode(:read)
        end
      end

      private

      def draw_header(width)
        terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}📖 Table of Contents#{Terminal::ANSI::RESET}")
        terminal.write(1, [width - 30, 40].max,
                       "#{Terminal::ANSI::DIM}[t/ESC] Back#{Terminal::ANSI::RESET}")
      end

      def draw_chapter_list(height, width)
        list_start = 4
        list_height = height - 6
        chapters = reader.send(:doc).chapters

        visible_range = calculate_visible_range(list_height, chapters.length)

        visible_range.each_with_index do |idx, row|
          chapter = chapters[idx]
          draw_chapter_item(chapter, idx, list_start + row, width)
        end
      end

      def draw_chapter_item(chapter, idx, row, width)
        number = idx + 1
        title = chapter[:title] || 'Untitled'
        text = "#{number}. #{title}"

        if idx == @selected
          terminal.write(row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
          terminal.write(row, 4, "#{Terminal::ANSI::BRIGHT_WHITE}#{text[0, width - 6]}#{Terminal::ANSI::RESET}")
        else
          terminal.write(row, 4, "#{Terminal::ANSI::WHITE}#{text[0, width - 6]}#{Terminal::ANSI::RESET}")
        end
      end

      def draw_footer(height)
        terminal.write(height - 1, 2,
                       "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Select • t/ESC Back#{Terminal::ANSI::RESET}")
      end

      def calculate_visible_range(list_height, total)
        visible_start = [@selected - (list_height / 2), 0].max
        visible_end = [visible_start + list_height, total].min
        visible_start...visible_end
      end
    end
  end
end
