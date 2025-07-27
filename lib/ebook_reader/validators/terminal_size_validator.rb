# frozen_string_literal: true

require_relative '../infrastructure/validator'

module EbookReader
  module Validators
    # Validates terminal dimensions for proper display.
    # Ensures terminal is large enough for the reader interface.
    class TerminalSizeValidator < Infrastructure::Validator
      # Minimum terminal dimensions
      MIN_WIDTH = Constants::UIConstants::MIN_WIDTH
      MIN_HEIGHT = Constants::UIConstants::MIN_HEIGHT

      # Recommended terminal dimensions for optimal experience
      RECOMMENDED_WIDTH = 80
      RECOMMENDED_HEIGHT = 24

      # Validate terminal size
      #
      # @param width [Integer] Terminal width
      # @param height [Integer] Terminal height
      # @return [Boolean] Validation result
      def validate(width, height)
        clear_errors

        validate_minimum_width(width) &
          validate_minimum_height(height)
      end

      # Check if terminal meets recommended size
      #
      # @param width [Integer] Terminal width
      # @param height [Integer] Terminal height
      # @return [Boolean] true if recommended size or larger
      def recommended_size?(width, height)
        width >= RECOMMENDED_WIDTH && height >= RECOMMENDED_HEIGHT
      end

      # Get size recommendations
      #
      # @param width [Integer] Current width
      # @param height [Integer] Current height
      # @return [Hash] Recommendations
      def recommendations(width, height)
        {
          current: { width:, height: },
          minimum: { width: MIN_WIDTH, height: MIN_HEIGHT },
          recommended: { width: RECOMMENDED_WIDTH, height: RECOMMENDED_HEIGHT },
          needs_resize: !recommended_size?(width, height),
        }
      end

      private

      def validate_minimum_width(width)
        range_valid?(width, MIN_WIDTH..Float::INFINITY, :width,
                     "Terminal width must be at least #{MIN_WIDTH} columns")
      end

      def validate_minimum_height(height)
        range_valid?(height, MIN_HEIGHT..Float::INFINITY, :height,
                     "Terminal height must be at least #{MIN_HEIGHT} rows")
      end
    end
  end
end
