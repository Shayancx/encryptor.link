# frozen_string_literal: true

module EbookReader
  module UI
    # Renders a single recent book item
    class RecentItemRenderer
      Context = Struct.new(:list_start, :height, :width, :selected_index, keyword_init: true)

      def initialize(book:, index:, menu:)
        @book = book
        @index = index
        @menu = menu
      end

      def render(context)
        row_base = context.list_start + (@index * 2)
        return if row_base >= context.height - 2

        render_title(row_base, context.selected_index)
        render_time(row_base, context.width)
        return unless row_base + 1 < context.height - 2

        render_path(row_base + 1, context.width)
      end

      private

      def render_title(row, selected_index)
        if @index == selected_index
          Terminal.write(row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
          Terminal.write(row, 4, Terminal::ANSI::BRIGHT_WHITE + (@book['name'] || 'Unknown') + Terminal::ANSI::RESET)
        else
          Terminal.write(row, 2, '  ')
          Terminal.write(row, 4, Terminal::ANSI::WHITE + (@book['name'] || 'Unknown') + Terminal::ANSI::RESET)
        end
      end

      def render_time(row, width)
        return unless @book['accessed']

        time_ago = @menu.send(:time_ago_in_words, Time.parse(@book['accessed']))
        Terminal.write(row, [width - 20, 60].max, Terminal::ANSI::DIM + time_ago + Terminal::ANSI::RESET)
      end

      def render_path(row, width)
        path = (@book['path'] || '').sub(Dir.home, '~')
        Terminal.write(row, 6,
                       Terminal::ANSI::DIM + Terminal::ANSI::GRAY + path[0, width - 8] + Terminal::ANSI::RESET)
      end
    end
  end
end
