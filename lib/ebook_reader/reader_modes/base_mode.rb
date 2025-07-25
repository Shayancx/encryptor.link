# frozen_string_literal: true

module EbookReader
  module ReaderModes
    # Base class for all reader modes
    class BaseMode
      attr_reader :reader

      def initialize(reader)
        @reader = reader
      end

      # @abstract Override in subclasses
      def draw(height, width)
        raise NotImplementedError
      end

      # @abstract Override in subclasses
      def handle_input(key)
        raise NotImplementedError
      end

      protected

      def terminal
        Terminal
      end

      def config
        reader.config
      end
    end
  end
end
