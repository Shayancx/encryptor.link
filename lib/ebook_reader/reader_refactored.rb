# frozen_string_literal: true

# This file contains refactored methods extracted from Reader class
module EbookReader
  module ReaderRefactored
    # Extract complex navigation logic
    module NavigationHelpers
      def calculate_navigation_params
        height, width = Terminal.size
        col_width, content_height = get_layout_metrics(width, height)
        content_height = adjust_for_line_spacing(content_height)
        
        chapter = @doc.get_chapter(@current_chapter)
        return nil unless chapter
        
        wrapped = wrap_lines(chapter[:lines] || [], col_width)
        max_page = [wrapped.size - content_height, 0].max
        
        [content_height, max_page, wrapped]
      end
      
      def update_page_position_split(direction, content_height, max_page)
        case direction
        when :next
          if @right_page < max_page
            @left_page = @right_page
            @right_page = [@right_page + content_height, max_page].min
            true
          else
            false
          end
        when :prev
          if @left_page.positive?
            @right_page = @left_page
            @left_page = [@left_page - content_height, 0].max
            true
          else
            false
          end
        end
      end
      
      def update_page_position_single(direction, content_height, max_page)
        case direction
        when :next
          if @single_page < max_page
            @single_page = [@single_page + content_height, max_page].min
            true
          else
            false
          end
        when :prev
          if @single_page.positive?
            @single_page = [@single_page - content_height, 0].max
            true
          else
            false
          end
        end
      end
    end
    
    # Extract drawing helpers
    module DrawingHelpers
      def draw_line_with_formatting(line, row, start_col, width)
        if should_highlight_line?(line)
          draw_highlighted_line(line, row, start_col, width)
        else
          Terminal.write(row, start_col, Terminal::ANSI::WHITE + line[0, width] + Terminal::ANSI::RESET)
        end
      end
      
      def calculate_visible_lines(lines, offset, height)
        end_offset = [offset + height, lines.size].min
        lines[offset...end_offset] || []
      end
      
      def render_page_indicator(start_row, start_col, width, height, offset, actual_height, lines)
        return unless @config.show_page_numbers && lines.size.positive? && actual_height.positive?
        
        page_num = (offset / actual_height) + 1
        total_pages = [(lines.size.to_f / actual_height).ceil, 1].max
        page_text = "#{page_num}/#{total_pages}"
        page_row = start_row + height - 1
        
        return if page_row >= Terminal.size[0] - Constants::PAGE_NUMBER_PADDING
        
        Terminal.write(page_row, [start_col + width - page_text.length, start_col].max,
                       Terminal::ANSI::DIM + Terminal::ANSI::GRAY + page_text + Terminal::ANSI::RESET)
      end
    end
    
    # Extract bookmark helpers
    module BookmarkHelpers
      def create_bookmark_data
        line_offset = @config.view_mode == :split ? @left_page : @single_page
        chapter = @doc.get_chapter(@current_chapter)
        return nil unless chapter
        
        text_snippet = extract_bookmark_text(chapter, line_offset)
        {
          path: @path,
          chapter: @current_chapter,
          line_offset: line_offset,
          text: text_snippet
        }
      end
      
      def jump_to_bookmark_position(bookmark)
        @current_chapter = bookmark['chapter']
        self.page_offsets = bookmark['line_offset']
        save_progress
        @mode = :read
      end
    end
  end
end
