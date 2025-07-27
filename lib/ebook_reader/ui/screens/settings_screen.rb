# frozen_string_literal: true

module EbookReader
  module UI
    module Screens
      # Presents application settings and allows users to toggle
      # various configuration options.
      class SettingsScreen
        def initialize(config, scanner)
          @config = config
          @scanner = scanner
        end

        def draw(height, width)
          render_header(width)
          settings = build_settings_list
          render_settings_list(settings, height)
          render_settings_status if @scanner.scan_message && @scanner.scan_status == :idle
          render_footer(height)
        end

        private

        def render_header(width)
          Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}⚙️  Settings#{Terminal::ANSI::RESET}")
          Terminal.write(1, [width - 20, 60].max, "#{Terminal::ANSI::DIM}[ESC] Back#{Terminal::ANSI::RESET}")
        end

        def build_settings_list
          [
            {
              name: 'View Mode',
              value: view_mode_description,
              key: '1',
            },
            {
              name: 'Show Page Numbers',
              value: @config.show_page_numbers ? 'Yes' : 'No',
              key: '2',
            },
            {
              name: 'Line Spacing',
              value: @config.line_spacing.to_s.capitalize,
              key: '3',
            },
            {
              name: 'Highlight Quotes',
              value: @config.highlight_quotes ? 'Yes' : 'No',
              key: '4',
            },
            {
              name: 'Clear Cache',
              value: 'Force rescan of EPUB files',
              key: '5',
              action: true,
            },
            {
              name: 'Page Numbering Mode',
              value: @config.page_numbering_mode == :absolute ? 'Absolute' : 'Dynamic',
              key: '6',
            },
          ]
        end

        def view_mode_description
          @config.view_mode == :split ? 'Split View (Two Pages)' : 'Single Page (Centered)'
        end

        def render_settings_list(settings, height)
          start_row = 5
          settings.each_with_index do |setting, i|
            row_base = start_row + (i * 3)
            next if row_base >= height - 4

            render_setting_item(setting, row_base, height)
          end
        end

        def render_setting_item(setting, row_base, height)
          Terminal.write(row_base, 4,
                         "#{Terminal::ANSI::YELLOW}[#{setting[:key]}]" \
                         "#{Terminal::ANSI::WHITE} #{setting[:name]}#{Terminal::ANSI::RESET}")

          return unless row_base + 1 < height - 3

          color = setting[:action] ? Terminal::ANSI::CYAN : Terminal::ANSI::BRIGHT_GREEN
          Terminal.write(row_base + 1, 8, color + setting[:value] + Terminal::ANSI::RESET)
        end

        def render_settings_status
          settings_count = 6
          row = 5 + (settings_count * 3) + 1
          Terminal.write(row, 4, Terminal::ANSI::YELLOW + @scanner.scan_message + Terminal::ANSI::RESET)
        end

        def render_footer(height)
          Terminal.write(height - 3, 4,
                         "#{Terminal::ANSI::DIM}Press number keys to toggle settings#{Terminal::ANSI::RESET}")
          Terminal.write(height - 2, 4,
                         "#{Terminal::ANSI::DIM}Changes are saved automatically#{Terminal::ANSI::RESET}")
        end
      end
    end
  end
end
