# frozen_string_literal: true

module EbookReader
  module Renderers
    # Base renderer class
    class BaseRenderer
      include Constants::UIConstants

      attr_reader :config

      def initialize(config)
        @config = config
      end

      protected

      def terminal
        Terminal
      end

      def write(row, col, text)
        terminal.write(row, col, text)
      end

      def with_color(color, text)
        "#{color}#{text}#{Terminal::ANSI::RESET}"
      end
    end
  end
end
