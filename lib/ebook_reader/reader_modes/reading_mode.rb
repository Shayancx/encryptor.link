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
        if navigation_key?(key)
          handle_navigation(key)
        elsif mode_switch_key?(key)
          handle_mode_switch(key)
        elsif view_adjustment_key?(key)
          handle_view_adjustment(key)
        elsif action_key?(key)
          handle_action(key)
        end
      end

      private

      def navigation_key?(key)
        %w[j k l h n p g G].include?(key) ||
          ["\e[A", "\e[B", "\e[C", "\e[D", "\eOA", "\eOB", "\eOC", "\eOD", ' '].include?(key)
      end

      def mode_switch_key?(key)
        %w[t T b B ?].include?(key)
      end

      def view_adjustment_key?(key)
        %w[v V + -].include?(key)
      end

      def action_key?(key)
        %w[q Q].include?(key)
      end

      def handle_navigation(key)
        case key
        when 'j', "\e[B", "\eOB" then reader.scroll_down
        when 'k', "\e[A", "\eOA" then reader.scroll_up
        when 'l', ' ', "\e[C", "\eOC" then reader.next_page
        when 'h', "\e[D", "\eOD" then reader.prev_page
        when 'n', 'N' then reader.next_chapter
        when 'p', 'P' then reader.prev_chapter
        when 'g' then reader.go_to_start
        when 'G' then reader.go_to_end
        end
      end

      def handle_mode_switch(key)
        case key
        when 't', 'T' then reader.switch_mode(:toc)
        when 'b' then reader.add_bookmark
        when 'B' then reader.switch_mode(:bookmarks)
        when '?' then reader.switch_mode(:help)
        end
      end

      def handle_view_adjustment(key)
        case key
        when 'v', 'V' then reader.toggle_view_mode
        when '+' then reader.increase_line_spacing
        when '-' then reader.decrease_line_spacing
        end
      end

      def handle_action(key)
        case key
        when 'q' then reader.quit_to_menu
        when 'Q' then reader.quit_application
        end
      end

      def draw_split_view(height, width)
        reader.send(:draw_split_screen, height, width)
      end

      def draw_single_view(height, width)
        reader.send(:draw_single_screen, height, width)
      end
    end
  end
end
