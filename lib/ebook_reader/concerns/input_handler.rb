# frozen_string_literal: true

module EbookReader
  module Concerns
    # Handles input for various screens
    module InputHandler
      def handle_navigation_keys(key, selected, max)
        case key
        when 'j', "\e[B", "\eOB"
          [selected + 1, max].min
        when 'k', "\e[A", "\eOA"
          [selected - 1, 0].max
        else
          selected
        end
      end

      def escape_key?(key)
        ["\e", "\x1B", 'q'].include?(key)
      end

      def enter_key?(key)
        ["\r", "\n"].include?(key)
      end

      def backspace_key?(key)
        ["\b", "\x7F", "\x08"].include?(key)
      end
    end
  end
end
