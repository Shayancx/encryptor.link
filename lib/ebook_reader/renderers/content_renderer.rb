# frozen_string_literal: true

require_relative 'base_renderer'

module EbookReader
  module Renderers
    # Renders document content
    class ContentRenderer < BaseRenderer
      def draw_single_view(chapter, width, height, page_offset)
        return unless chapter

        col_width = calculate_single_column_width(width)
        col_start = center_column(width, col_width)
        content_height = calculate_content_height(height, :single)

        wrapped = wrap_lines(chapter[:lines] || [], col_width)
        start_row = center_vertically(height, content_height)

        draw_column(start_row, col_start, col_width, content_height, wrapped, page_offset, false)
      end

      def draw_split_view(chapter, width, height, left_offset, right_offset)
        return unless chapter

        col_width = calculate_split_column_width(width)
        content_height = calculate_content_height(height, :split)
        wrapped = wrap_lines(chapter[:lines] || [], col_width)

        draw_chapter_header(chapter, width)
        draw_left_column(wrapped, col_width, content_height, left_offset)
        draw_divider(height, col_width)
        draw_right_column(wrapped, col_width, content_height, right_offset)
      end

      private

      def calculate_single_column_width(width)
        [(width * 0.9).to_i, SINGLE_VIEW_MAX_WIDTH].min.clamp(MIN_COLUMN_WIDTH, width - 4)
      end

      def calculate_split_column_width(width)
        [(width - SPLIT_VIEW_DIVIDER_WIDTH) / 2, MIN_COLUMN_WIDTH].max
      end

      def calculate_content_height(height, mode)
        base_height = height - HEADER_HEIGHT - FOOTER_HEIGHT

        if @config.line_spacing == :relaxed
          # In relaxed mode, each line takes up two rows.
          (base_height / 2.0).floor
        else
          base_height
        end
      end

      def center_column(width, col_width)
        [(width - col_width) / 2, 1].max
      end

      def center_vertically(height, content_height)
        content_rows = if @config.line_spacing == :relaxed
                         content_height * 2
                       else
                         content_height
                       end

        available_rows = height - HEADER_HEIGHT - FOOTER_HEIGHT
        padding = available_rows - content_rows

        [HEADER_HEIGHT + (padding / 2), HEADER_HEIGHT].max
      end

      def draw_chapter_header(chapter, width)
        title = "[#{chapter[:number] || 1}] #{chapter[:title] || 'Unknown'}"
        write(2, 1, with_color(Terminal::ANSI::BLUE, title[0, width - 2]))
      end

      def draw_left_column(wrapped, width, height, offset)
        draw_column(3, 1, width, height, wrapped, offset, true)
      end

      def draw_right_column(wrapped, width, height, offset)
        draw_column(3, width + SPLIT_VIEW_DIVIDER_WIDTH, width, height, wrapped, offset, false)
      end

      def draw_divider(height, col_width)
        (3...[height - 1, 4].max).each do |row|
          write(row, col_width + 3, with_color(Terminal::ANSI::GRAY, DIVIDER_SYMBOL))
        end
      end

      def draw_column(start_row, start_col, width, height, lines, offset, show_page_num)
        return if lines.nil? || lines.empty? || width < 10 || height < 1

        actual_height = height
        end_offset = [offset + actual_height, lines.size].min

        draw_lines(lines, offset, end_offset, start_row, start_col, width, actual_height)
        draw_page_number(start_row, start_col, width, height, offset, actual_height, lines) if show_page_num
      end

      def draw_lines(lines, start_offset, end_offset, start_row, start_col, width, actual_height)
        line_count = 0
        (start_offset...end_offset).each do |line_idx|
          break if line_count >= actual_height

          line = lines[line_idx] || ''
          row = calculate_row(start_row, line_count)

          next if row >= Terminal.size[0] - 2

          draw_line(line, row, start_col, width)
          line_count += 1
        end
      end

      def calculate_row(start_row, line_count)
        if @config.line_spacing == :relaxed
          start_row + (line_count * 2)
        else
          start_row + line_count
        end
      end

      def draw_line(line, row, start_col, width)
        text = line[0, width]
        write(row, start_col, with_color(Terminal::ANSI::WHITE, text))
      end

      def draw_page_number(start_row, start_col, width, height, offset, actual_height, lines)
        return unless @config.show_page_numbers && lines.size.positive? && actual_height.positive?

        page_num = (offset / actual_height) + 1
        total_pages = [(lines.size.to_f / actual_height).ceil, 1].max
        page_text = "#{page_num}/#{total_pages}"
        page_row = start_row + height - 1

        return if page_row >= Terminal.size[0] - 2

        write(page_row, [start_col + width - page_text.length, start_col].max,
              with_color(Terminal::ANSI::DIM + Terminal::ANSI::GRAY, page_text))
      end

      def wrap_lines(lines, _width)
        # Placeholder - should use existing ReaderHelpers
        lines
      end
    end
  end
end
