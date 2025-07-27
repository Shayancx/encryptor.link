# frozen_string_literal: true

module EbookReader
  module UI
    module Screens
      # Screen for entering a file path to open an EPUB.
      class OpenFileScreen
        attr_accessor :input

        def initialize
          @input = ''
        end

        def draw(height, width)
          Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}󰷏 Open File#{Terminal::ANSI::RESET}")
          Terminal.write(1, [width - 20, 60].max, "#{Terminal::ANSI::DIM}[ESC] Cancel#{Terminal::ANSI::RESET}")

          prompt = 'Enter EPUB path: '
          col = [(width - prompt.length - 40) / 2, 2].max
          row = height / 2
          Terminal.write(row, col, Terminal::ANSI::WHITE + prompt + Terminal::ANSI::RESET)
          Terminal.write(row, col + prompt.length, "#{Terminal::ANSI::BRIGHT_WHITE}#{@input}_#{Terminal::ANSI::RESET}")

          footer = 'Enter to open • Backspace delete • ESC cancel'
          Terminal.write(height - 1, 2, Terminal::ANSI::DIM + footer + Terminal::ANSI::RESET)
        end
      end
    end
  end
end
