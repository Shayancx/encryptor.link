# frozen_string_literal: true

module EbookReader
  module Infrastructure
    # Base validator class providing common validation patterns.
    # Subclasses should implement specific validation logic.
    #
    # @abstract
    class Validator
      # Validation errors collection
      attr_reader :errors

      def initialize
        @errors = []
      end

      # Check if validation passed
      #
      # @return [Boolean] true if no errors
      def valid?
        @errors.empty?
      end

      # Add an error message
      #
      # @param field [Symbol] Field name
      # @param message [String] Error message
      def add_error(field, message)
        @errors << { field:, message: }
      end

      # Clear all errors
      def clear_errors
        @errors = []
      end

      # Validate presence of a value
      #
      # @param value [Object] Value to check
      # @param field [Symbol] Field name for error reporting
      # @param message [String] Custom error message
      # @return [Boolean] Validation result
      def presence_valid?(value, field, message = "can't be blank")
        return true if value && !value.to_s.strip.empty?

        add_error(field, message)
        false
      end

      # Validate value is within a range
      #
      # @param value [Numeric] Value to check
      # @param range [Range] Valid range
      # @param field [Symbol] Field name for error reporting
      # @param message [String] Custom error message
      # @return [Boolean] Validation result
      def range_valid?(value, range, field, message = nil)
        return true if range.include?(value)

        message ||= "must be between #{range.min} and #{range.max}"
        add_error(field, message)
        false
      end

      # Validate value matches a pattern
      #
      # @param value [String] Value to check
      # @param pattern [Regexp] Pattern to match
      # @param field [Symbol] Field name for error reporting
      # @param message [String] Custom error message
      # @return [Boolean] Validation result
      def format_valid?(value, pattern, field, message = 'has invalid format')
        return true if value.to_s.match?(pattern)

        add_error(field, message)
        false
      end
    end
  end
end
