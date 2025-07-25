# frozen_string_literal: true

module EbookReader
  module UI
    # Handles rendering for MainMenu
    class MainMenuRenderer
      include Terminal::ANSI

      def initialize(config)
        @config = config
      end

      def render_logo(height, width)
        logo = [
          '   _____ _                 __        _   __                __   ____                __         ',
          "  / ___/(_)___ ___  ____  / /__     / | / /___ _   _____  / /  / __ \___  ____ _____/ /__  _____",
          "  \__ \/ / __ `__ \/ __ \/ / _ \   /  |/ / __ \ | / / _ \/ /  / /_/ / _ \/ __ `/ __  / _ \/ ___/",
          ' ___/ / / / / / / /_/ / /  __/  / /|  / /_/ / |/ /  __/ /  / _, _/  __/ /_/ / /_/ /  __/ /    ',
          "/____/_/_/ /_/ /_/ .___/_/\___/  /_/ |_/\____/|___/\___/_/  /_/ |_|\___/\__,_/\__,_/\___/_/     ",
          '                /_/                                                                              '
        ]

        logo_start = [((height - logo.length - 15) / 2), 2].max
        logo.each_with_index do |line, i|
          col = [(width - line.length) / 2, 1].max
          Terminal.write(logo_start + i, col, CYAN + line + RESET)
        end

        version_text = "version #{VERSION}"
        Terminal.write(logo_start + logo.length + 1, (width - version_text.length) / 2,
                       DIM + WHITE + version_text + RESET)
        logo_start + logo.length + 5
      end

      def render_menu_item(row, pointer_col, text_col, item, selected)
        if selected
          Terminal.write(row, pointer_col, "#{BRIGHT_GREEN}▸ #{RESET}")
          Terminal.write(row, text_col,
                         "#{BRIGHT_WHITE}#{item[:icon]}  #{BRIGHT_YELLOW}[#{item[:key]}]" \
                         "#{BRIGHT_WHITE} #{item[:text]}#{GRAY} — #{item[:desc]}#{RESET}")
        else
          Terminal.write(row, pointer_col, '  ')
          Terminal.write(row, text_col,
                         "#{WHITE}#{item[:icon]}  #{YELLOW}[#{item[:key]}]" \
                         "#{WHITE} #{item[:text]}#{DIM}#{GRAY} — #{item[:desc]}#{RESET}")
        end
      end

      def render_footer(height, width, text)
        Terminal.write(height - 1, [(width - text.length) / 2, 1].max,
                       DIM + WHITE + text + RESET)
      end
    end
  end
end
