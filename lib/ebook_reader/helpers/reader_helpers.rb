# frozen_string_literal: true

module EbookReader
  module Helpers
    # Helper methods for Reader
    module ReaderHelpers
      def wrap_lines(lines, width)
        return [] if lines.nil? || width < 10

        @wrap_cache ||= {}
        key = "#{lines.object_id}_#{width}"
        return @wrap_cache[key] if @wrap_cache[key]

        wrapped = []
        lines.each do |line|
          next if line.nil?

          if line.strip.empty?
            wrapped << ''
          else
            wrap_line(line, width, wrapped)
          end
        end
        @wrap_cache[key] = wrapped
      end

      private

      def wrap_line(line, width, wrapped)
        words = line.split(/\s+/)
        current = ''

        words.each do |word|
          next if word.nil?

          if current.empty?
            current = word
          elsif current.length + 1 + word.length <= width
            current += " #{word}"
          else
            wrapped << current
            current = word
          end
        end

        wrapped << current unless current.empty?
      end
    end
  end
end
