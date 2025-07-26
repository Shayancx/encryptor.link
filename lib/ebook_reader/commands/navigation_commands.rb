# frozen_string_literal: true

require_relative 'base_command'

module EbookReader
  module Commands
    # Scroll down by one line
    class ScrollDownCommand < BaseCommand
      def execute
        receiver.send(:scroll_down)
      end
    end

    # Scroll up by one line
    class ScrollUpCommand < BaseCommand
      def execute
        receiver.send(:scroll_up)
      end
    end

    # Go to next page
    class NextPageCommand < BaseCommand
      def execute
        height, width = Terminal.size
        _, content_height = receiver.send(:get_layout_metrics, width, height)
        content_height = receiver.send(:adjust_for_line_spacing, content_height)
        max_page = receiver.instance_variable_get(:@max_page) || 0
        receiver.send(:next_page, content_height, max_page)
      end
    end

    # Go to previous page
    class PrevPageCommand < BaseCommand
      def execute
        height, width = Terminal.size
        _, content_height = receiver.send(:get_layout_metrics, width, height)
        content_height = receiver.send(:adjust_for_line_spacing, content_height)
        receiver.send(:prev_page, content_height)
      end
    end

    # Go to next chapter
    class NextChapterCommand < BaseCommand
      def execute
        doc = receiver.instance_variable_get(:@doc)
        current = receiver.instance_variable_get(:@current_chapter)
        receiver.send(:next_chapter) if current < doc.chapter_count - 1
      end
    end

    # Go to previous chapter
    class PrevChapterCommand < BaseCommand
      def execute
        current = receiver.instance_variable_get(:@current_chapter)
        receiver.send(:prev_chapter) if current.positive?
      end
    end

    # Go to beginning of chapter
    class GoToStartCommand < BaseCommand
      def execute
        receiver.send(:reset_pages)
      end
    end

    # Go to end of chapter
    class GoToEndCommand < BaseCommand
      def execute
        height, width = Terminal.size
        _, content_height = receiver.send(:get_layout_metrics, width, height)
        content_height = receiver.send(:adjust_for_line_spacing, content_height)
        max_page = receiver.instance_variable_get(:@max_page) || 0
        receiver.send(:go_to_end, content_height, max_page)
      end
    end
  end
end
