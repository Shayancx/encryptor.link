# frozen_string_literal: true

module EbookReader
  module Helpers
    # Helps with wrapping long lines
    module LineWrapper
      def self.wrap_terminal_write(row, col, text, max_length = 120)
        if text.length > max_length
          parts = split_long_text(text, max_length)
          parts.each_with_index do |part, i|
            Terminal.write(row + i, col, part)
          end
        else
          Terminal.write(row, col, text)
        end
      end

      def self.split_long_text(text, max_length)
        parts = []
        remaining = text
        while remaining.length > max_length
          split_point = find_split_point(remaining, max_length)
          parts << remaining[0...split_point]
          remaining = remaining[split_point..]
        end
        parts << remaining unless remaining.empty?
        parts
      end

      private_class_method def self.find_split_point(text, max_length)
        # Try to split at a space
        last_space = text[0...max_length].rindex(' ')
        last_space && last_space > max_length * 0.7 ? last_space : max_length
      end
    end
  end
end
