# frozen_string_literal: true

module EbookReader
  module Models
    # Parameters for drawing a column in the reader
    class ColumnDrawingParams
      Position = Struct.new(:row, :col, keyword_init: true)
      Dimensions = Struct.new(:width, :height, keyword_init: true)
      Content = Struct.new(:lines, :offset, :show_page_num, keyword_init: true)

      attr_reader :position, :dimensions, :content

      def initialize(position:, dimensions:, content:)
        @position = position
        @dimensions = dimensions
        @content = content
      end
    end
  end
end
