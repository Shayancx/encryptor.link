# frozen_string_literal: true

require_relative 'base_mode'

module EbookReader
  module ReaderModes
    # Handles the main reading view
    class ReadingMode < BaseMode
      def draw(height, width)
        if config.view_mode == :split
          draw_split_view(height, width)
        else
          draw_single_view(height, width)
        end
      end

      def handle_input(key)
        case key
        when 'j', "\e[B", "\eOB" then reader.scroll_down
        when 'k', "\e[A", "\eOA" then reader.scroll_up
        when 'l', ' ', "\e[C", "\eOC" then reader.next_page
        when 'h', "\e[D", "\eOD" then reader.prev_page
        when 'n', 'N' then reader.next_chapter
        when 'p', 'P' then reader.prev_chapter
        when 'g' then reader.go_to_start
        when 'G' then reader.go_to_end
        when 't', 'T' then reader.switch_mode(:toc)
        when 'b' then reader.add_bookmark
        when 'B' then reader.switch_mode(:bookmarks)
        when '?' then reader.switch_mode(:help)
        when 'v', 'V' then reader.toggle_view_mode
        when '+' then reader.increase_line_spacing
        when '-' then reader.decrease_line_spacing
        when 'q' then reader.quit_to_menu
        when 'Q' then reader.quit_application
        end
      end

      private

      def draw_split_view(height, width)
        reader.send(:draw_split_screen, height, width)
      end

      def draw_single_view(height, width)
        reader.send(:draw_single_screen, height, width)
      end
    end
  end
end
