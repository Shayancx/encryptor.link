# frozen_string_literal: true

require 'io/console'

module EbookReader
  # A utility class for terminal manipulation.
  #
  # Provides methods for clearing the screen, moving the cursor, and handling
  # raw keyboard input. It uses a double-buffering technique to minimize
  # flicker during screen updates.
  class Terminal
    # A collection of ANSI escape codes for styling and controlling the terminal.
    module ANSI
      # Text styling
      RESET = "\e[0m"
      BOLD = "\e[1m"
      DIM = "\e[2m"
      ITALIC = "\e[3m"

      # Standard colors
      BLACK = "\e[30m"
      RED = "\e[31m"
      GREEN = "\e[32m"
      YELLOW = "\e[33m"
      BLUE = "\e[34m"
      MAGENTA = "\e[35m"
      CYAN = "\e[36m"
      WHITE = "\e[37m"
      GRAY = "\e[90m"

      # Bright colors
      BRIGHT_RED = "\e[91m"
      BRIGHT_GREEN = "\e[92m"
      BRIGHT_YELLOW = "\e[93m"
      BRIGHT_BLUE = "\e[94m"
      BRIGHT_MAGENTA = "\e[95m"
      BRIGHT_CYAN = "\e[96m"
      BRIGHT_WHITE = "\e[97m"

      # Background colors
      BG_DARK = "\e[48;5;236m"

      # Control sequences
      module Control
        CLEAR = "\e[2J"
        HOME = "\e[H"
        HIDE_CURSOR = "\e[?25l"
        SHOW_CURSOR = "\e[?25h"
        SAVE_SCREEN = "\e[?1049h"
        RESTORE_SCREEN = "\e[?1049l"
      end

      def self.move(row, col)
        "\e[#{row};#{col}H"
      end

      def self.clear_line
        "\e[2K"
      end

      def self.clear_below
        "\e[J"
      end
    end

    @buffer = []

    class << self
      def size
        IO.console.winsize || [24, 80]
      rescue StandardError
        [24, 80]
      end

      def clear
        print [ANSI::Control::CLEAR, ANSI::Control::HOME].join
        $stdout.flush
      end

      def move(row, col)
        @buffer << ANSI.move(row, col)
      end

      def write(row, col, text)
        @buffer << (ANSI.move(row, col) + text.to_s)
      end

      def start_frame
        @buffer = [ANSI::Control::CLEAR, ANSI::Control::HOME]
      end

      def end_frame
        print @buffer.join
        $stdout.flush
      end

      def setup
        $stdout.sync = true
        print [
          ANSI::Control::SAVE_SCREEN,
          ANSI::Control::HIDE_CURSOR,
          ANSI::BG_DARK
        ].join
        clear

        setup_signal_handlers
      end

      def cleanup
        print [
          ANSI::Control::CLEAR,
          ANSI::Control::HOME,
          ANSI::Control::SHOW_CURSOR,
          ANSI::Control::RESTORE_SCREEN,
          ANSI::RESET
        ].join
        $stdout.flush
      end

      def read_key
        IO.console.raw do
          input = $stdin.read_nonblock(1)
          return input unless input == "\e"

          begin
            input << $stdin.read_nonblock(3)
          rescue IO::WaitReadable
            # Not a full escape sequence, just the escape key.
          end
          input
        end
      rescue IO::WaitReadable
        nil # No input available
      end

      private

      def setup_signal_handlers
        %w[INT TERM].each do |signal|
          trap(signal) do
            cleanup
            exit(0)
          end
        end
      end
    end
  end
end
