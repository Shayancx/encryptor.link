# frozen_string_literal: true

module EbookReader
  module Commands
    # Base class for all commands
    class BaseCommand
      attr_reader :receiver

      def initialize(receiver)
        @receiver = receiver
      end

      # Execute the command
      # @abstract
      def execute
        raise NotImplementedError
      end

      # Optional: undo the command
      def undo
        # Override in subclasses if needed
      end
    end
  end
end
