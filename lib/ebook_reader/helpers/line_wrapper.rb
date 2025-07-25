# frozen_string_literal: true

module EbookReader
  module Helpers
    # Helps with wrapping long lines
    module LineWrapper
      Coordinates = Struct.new(:row, :col)

      DEFAULT_MAX_LENGTH = 120

      def self.wrap_terminal_write(position, text, max_length = DEFAULT_MAX_LENGTH)
        if text.length > max_length
          split_long_text(text, max_length).each_with_index do |part, index|
            Terminal.write(position.row + index, position.col, part)
          end
        else
          Terminal.write(position.row, position.col, text)
        end
      end

      def self.split_long_text(text, max_length)
        return [text] if text.length <= max_length

        split_point = find_split_point(text, max_length)
        [text[0...split_point]] + split_long_text(text[split_point..], max_length)
      end

      private_class_method def self.find_split_point(text, max_length)
        # Try to split at a space
        last_space = text[0...max_length].rindex(' ')
        last_space && last_space > max_length * 0.7 ? last_space : max_length
      end
    end
  end
end
