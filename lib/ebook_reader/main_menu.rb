# frozen_string_literal: true

require_relative 'ui/main_menu_renderer'
require_relative 'ui/browse_screen'
require_relative 'helpers/epub_scanner'
require_relative 'concerns/input_handler'

module EbookReader
  # Main menu (LazyVim style)
  class MainMenu
    include Concerns::InputHandler

    def initialize
      @selected = 0
      @mode = :menu
      @browse_selected = 0
      @search_query = ''
      @config = Config.new
      @scanner = Helpers::EPUBScanner.new
      @renderer = UI::MainMenuRenderer.new(@config)
      @browse_screen = UI::BrowseScreen.new
    end

    def run
      Terminal.setup
      @scanner.load_cached
      @scanner.start_scan if @scanner.epubs.empty?

      main_loop
    rescue Interrupt
      cleanup_and_exit(0, "\nGoodbye!")
    rescue StandardError => e
      cleanup_and_exit(1, "Error: #{e.message}", e)
    ensure
      @scanner.cleanup
    end

    private

    def main_loop
      loop do
        process_scan_results
        draw_screen
        handle_input(Terminal.read_key)
        sleep 0.02
      end
    end

    def process_scan_results
      if (epubs = @scanner.process_results)
        @scanner.epubs = epubs
        filter_books
      end
    end

    def cleanup_and_exit(code, message, error = nil)
      Terminal.cleanup
      puts message
      puts error.backtrace if error && EPUBFinder::DEBUG_MODE
      exit code
    end

    def draw_screen
      Terminal.start_frame
      height, width = Terminal.size

      case @mode
      when :menu then draw_main_menu(height, width)
      when :browse then draw_browse_screen(height, width)
      when :recent then draw_recent_screen(height, width)
      when :settings then draw_settings_screen(height, width)
      end

      Terminal.end_frame
    end

    def draw_main_menu(height, width)
      menu_start = @renderer.render_logo(height, width)
      menu_items = build_menu_items
      render_menu_items(menu_items, menu_start, height, width)
      @renderer.render_footer(height, width, 'Navigate with ↑↓ or jk • Select with Enter')
    end

    def build_menu_items
      [
        { key: 'f', icon: '', text: 'Find Book', desc: 'Browse all EPUBs' },
        { key: 'r', icon: '󰁯', text: 'Recent', desc: 'Recently opened books' },
        { key: 'o', icon: '󰷏', text: 'Open File', desc: 'Enter path manually' },
        { key: 's', icon: '', text: 'Settings', desc: 'Configure reader' },
        { key: 'q', icon: '󰿅', text: 'Quit', desc: 'Exit application' }
      ]
    end

    def render_menu_items(items, start_row, height, width)
      items.each_with_index do |item, i|
        row = start_row + (i * 2)
        next if row >= height - 2

        pointer_col = [(width / 2) - 20, 2].max
        text_col = [(width / 2) - 18, 4].max

        @renderer.render_menu_item(row, pointer_col, text_col, item, i == @selected)
      end
    end

    def draw_browse_screen(height, width)
      @browse_screen.render_header(width)
      @browse_screen.render_search_bar(@search_query)
      @browse_screen.render_status(@scanner.scan_status, @scanner.scan_message)

      if @filtered_epubs.empty?
        @browse_screen.render_empty_state(height, width, @scanner.scan_status, @scanner.epubs.empty?)
      else
        render_book_list(height, width)
      end

      render_browse_footer(height, width)
    end

    def render_book_list(height, width)
      list_start = 6
      list_height = [height - 8, 1].max

      visible_range = calculate_visible_range(list_height)
      render_visible_books(visible_range, list_start, list_height, width)
      render_scroll_indicator(list_start, list_height, width) if @filtered_epubs.length > list_height
    end

    def calculate_visible_range(list_height)
      visible_start = [@browse_selected - (list_height / 2), 0].max
      visible_end = [visible_start + list_height, @filtered_epubs.length].min

      if visible_end == @filtered_epubs.length && @filtered_epubs.length > list_height
        visible_start = [visible_end - list_height, 0].max
      end

      visible_start...visible_end
    end

    def render_visible_books(range, list_start, list_height, width)
      range.each_with_index do |idx, row|
        next if row >= list_height

        book = @filtered_epubs[idx]
        next unless book

        render_book_item(book, idx, list_start + row, width)
      end
    end

    def render_book_item(book, idx, row, width)
      name = (book['name'] || 'Unknown')[0, [width - 40, 40].max]

      if idx == @browse_selected
        Terminal.write(row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
        Terminal.write(row, 4, Terminal::ANSI::BRIGHT_WHITE + name + Terminal::ANSI::RESET)
      else
        Terminal.write(row, 2, '  ')
        Terminal.write(row, 4, Terminal::ANSI::WHITE + name + Terminal::ANSI::RESET)
      end

      render_book_path(book, row, width) if width > 60
    end

    def render_book_path(book, row, width)
      path = (book['dir'] || '').sub(Dir.home, '~')
      path = "#{path[0, 30]}..." if path.length > 33
      Terminal.write(row, [width - 35, 45].max,
                     Terminal::ANSI::DIM + Terminal::ANSI::GRAY + path + Terminal::ANSI::RESET)
    end

    def render_scroll_indicator(list_start, list_height, width)
      scroll_pos = @filtered_epubs.length > 1 ? @browse_selected.to_f / (@filtered_epubs.length - 1) : 0
      scroll_row = list_start + (scroll_pos * (list_height - 1)).to_i
      Terminal.write(scroll_row, width - 2, "#{Terminal::ANSI::BRIGHT_CYAN}▐#{Terminal::ANSI::RESET}")
    end

    def render_browse_footer(height, _width)
      Terminal.write(height - 1, 2,
                     Terminal::ANSI::DIM + "#{@filtered_epubs.length} books • " \
                                           '↑↓ Navigate • Enter Open • / Search • r Refresh • ESC Back' + Terminal::ANSI::RESET)
    end

    def draw_recent_screen(height, width)
      render_recent_header(width)
      recent = load_recent_books

      if recent.empty?
        render_empty_recent(height, width)
      else
        render_recent_list(recent, height, width)
      end

      render_recent_footer(height)
    end

    def render_recent_header(width)
      Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}🕒 Recent Books#{Terminal::ANSI::RESET}")
      Terminal.write(1, [width - 20, 60].max, "#{Terminal::ANSI::DIM}[ESC] Back#{Terminal::ANSI::RESET}")
    end

    def load_recent_books
      RecentFiles.load.select { |r| r && r['path'] && File.exist?(r['path']) }
    end

    def render_empty_recent(height, width)
      Terminal.write(height / 2, [(width - 20) / 2, 1].max,
                     "#{Terminal::ANSI::DIM}No recent books#{Terminal::ANSI::RESET}")
    end

    def render_recent_list(recent, height, width)
      list_start = 4
      max_items = [(height - 6) / 2, 10].min

      recent.take(max_items).each_with_index do |book, i|
        render_recent_item(book, i, list_start, height, width)
      end
    end

    def render_recent_item(book, index, list_start, height, width)
      row_base = list_start + (index * 2)
      return if row_base >= height - 2

      render_recent_title(book, index, row_base)
      render_recent_time(book, row_base, width)
      render_recent_path(book, row_base + 1, width) if row_base + 1 < height - 2
    end

    def render_recent_title(book, index, row)
      if index == @browse_selected
        Terminal.write(row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
        Terminal.write(row, 4, Terminal::ANSI::BRIGHT_WHITE + (book['name'] || 'Unknown') + Terminal::ANSI::RESET)
      else
        Terminal.write(row, 2, '  ')
        Terminal.write(row, 4, Terminal::ANSI::WHITE + (book['name'] || 'Unknown') + Terminal::ANSI::RESET)
      end
    end

    def render_recent_time(book, row, width)
      return unless book['accessed']

      time_ago = time_ago_in_words(Time.parse(book['accessed']))
      Terminal.write(row, [width - 20, 60].max, Terminal::ANSI::DIM + time_ago + Terminal::ANSI::RESET)
    end

    def render_recent_path(book, row, width)
      path = (book['path'] || '').sub(Dir.home, '~')
      Terminal.write(row, 6,
                     Terminal::ANSI::DIM + Terminal::ANSI::GRAY + path[0, width - 8] + Terminal::ANSI::RESET)
    end

    def render_recent_footer(height)
      Terminal.write(height - 1, 2,
                     "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Open • ESC Back#{Terminal::ANSI::RESET}")
    end

    def draw_settings_screen(height, width)
      render_settings_header(width)
      settings = build_settings_list
      render_settings_list(settings, height)
      render_settings_status if @scanner.scan_message && @scanner.scan_status == :idle
      render_settings_footer(height)
    end

    def render_settings_header(width)
      Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}⚙️  Settings#{Terminal::ANSI::RESET}")
      Terminal.write(1, [width - 20, 60].max, "#{Terminal::ANSI::DIM}[ESC] Back#{Terminal::ANSI::RESET}")
    end

    def build_settings_list
      [
        {
          name: 'View Mode',
          value: @config.view_mode == :split ? 'Split View (Two Pages)' : 'Single Page (Centered)',
          key: '1'
        },
        {
          name: 'Show Page Numbers',
          value: @config.show_page_numbers ? 'Yes' : 'No',
          key: '2'
        },
        {
          name: 'Line Spacing',
          value: @config.line_spacing.to_s.capitalize,
          key: '3'
        },
        {
          name: 'Highlight Quotes',
          value: @config.highlight_quotes ? 'Yes' : 'No',
          key: '4'
        },
        {
          name: 'Clear Cache',
          value: 'Force rescan of EPUB files',
          key: '5',
          action: true
        },
        {
          name: 'Page Numbering Mode',
          value: @config.page_numbering_mode == :absolute ? 'Absolute' : 'Dynamic',
          key: '6'
        }
      ]
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

    def render_settings_footer(height)
      Terminal.write(height - 3, 4,
                     "#{Terminal::ANSI::DIM}Press number keys to toggle settings#{Terminal::ANSI::RESET}")
      Terminal.write(height - 2, 4, "#{Terminal::ANSI::DIM}Changes are saved automatically#{Terminal::ANSI::RESET}")
    end

    def handle_input(key)
      return unless key

      case @mode
      when :menu then handle_menu_input(key)
      when :browse then handle_browse_input(key)
      when :recent then handle_recent_input(key)
      when :settings then handle_settings_input(key)
      end
    end

    def handle_menu_input(key)
      case key
      when 'q', 'Q' then cleanup_and_exit(0, '')
      when 'f', 'F' then switch_to_browse
      when 'r', 'R' then switch_to_mode(:recent)
      when 'o', 'O' then open_file_dialog
      when 's', 'S' then switch_to_mode(:settings)
      when 'j', "\e[B", "\eOB" then @selected = (@selected + 1) % 5
      when 'k', "\e[A", "\eOA" then @selected = (@selected - 1 + 5) % 5
      when "\r", "\n" then handle_menu_selection
      end
    end

    def switch_to_browse
      @mode = :browse
      @browse_selected = 0
      @scanner.start_scan if @scanner.epubs.empty? && @scanner.scan_status == :idle
    end

    def switch_to_mode(mode)
      @mode = mode
      @browse_selected = 0
    end

    def handle_menu_selection
      case @selected
      when 0 then switch_to_browse
      when 1 then switch_to_mode(:recent)
      when 2 then open_file_dialog
      when 3 then switch_to_mode(:settings)
      when 4 then cleanup_and_exit(0, '')
      end
    end

    def handle_browse_input(key)
      if escape_key?(key)
        @mode = :menu
      elsif %w[r R].include?(key)
        refresh_scan
      elsif navigation_key?(key)
        navigate_browse(key)
      elsif enter_key?(key)
        open_selected_book
      elsif key == '/'
        @search_query = ''
      elsif backspace_key?(key)
        handle_backspace
      elsif searchable_key?(key)
        add_to_search(key)
      end
    end

    def navigation_key?(key)
      ['j', 'k', "\e[A", "\e[B", "\eOA", "\eOB"].include?(key)
    end

    def navigate_browse(key)
      return unless @filtered_epubs.any?

      @browse_selected = handle_navigation_keys(key, @browse_selected, @filtered_epubs.length - 1)
    end

    def refresh_scan
      EPUBFinder.clear_cache
      @scanner.start_scan(force: true)
    end

    def open_selected_book
      return unless @filtered_epubs[@browse_selected]

      path = @filtered_epubs[@browse_selected]['path']
      if path && File.exist?(path)
        open_book(path)
      else
        @scanner.scan_message = 'File not found'
        @scanner.scan_status = :error
      end
    end

    def handle_backspace
      return unless @search_query.length.positive?

      @search_query = @search_query[0...-1]
      filter_books
    end

    def searchable_key?(key)
      return false unless key

      begin
        key = key.to_s.force_encoding('UTF-8')
        key.valid_encoding? && key =~ /[a-zA-Z0-9 .-]/
      rescue StandardError
        false
      end
    end

    def add_to_search(key)
      @search_query += key
      filter_books
    end

    def handle_recent_input(key)
      recent = load_recent_books

      if escape_key?(key)
        @mode = :menu
      elsif navigation_key?(key) && recent.any?
        @browse_selected = handle_navigation_keys(key, @browse_selected, recent.length - 1)
      elsif enter_key?(key)
        book = recent[@browse_selected]
        open_book(book['path']) if book && book['path'] && File.exist?(book['path'])
      end
    end

    def handle_settings_input(key)
      if escape_key?(key)
        @mode = :menu
        @config.save
      else
        handle_setting_change(key)
      end
    end

    def handle_setting_change(key)
      case key
      when '1' then toggle_view_mode
      when '2' then toggle_page_numbers
      when '3' then cycle_line_spacing
      when '4' then toggle_highlight_quotes
      when '5' then clear_cache
      when '6' then toggle_page_numbering_mode
      end
    end

    def toggle_view_mode
      @config.view_mode = @config.view_mode == :split ? :single : :split
      @config.save
    end

    def toggle_page_numbers
      @config.show_page_numbers = !@config.show_page_numbers
      @config.save
    end

    def cycle_line_spacing
      modes = %i[compact normal relaxed]
      current = modes.index(@config.line_spacing) || 1
      @config.line_spacing = modes[(current + 1) % 3]
      @config.save
    end

    def toggle_highlight_quotes
      @config.highlight_quotes = !@config.highlight_quotes
      @config.save
    end

    def toggle_page_numbering_mode
      @config.page_numbering_mode = @config.page_numbering_mode == :absolute ? :dynamic : :absolute
      @config.save
    end

    def clear_cache
      EPUBFinder.clear_cache
      @scanner.epubs = []
      @filtered_epubs = []
      @scanner.scan_status = :idle
      @scanner.scan_message = "Cache cleared! Use 'Find Book' to rescan"
    end

    def filter_books
      @filtered_epubs = if @search_query.empty?
                          @scanner.epubs
                        else
                          filter_by_query
                        end
      @browse_selected = 0
    end

    def filter_by_query
      query = @search_query.downcase
      @scanner.epubs.select do |book|
        name = book['name'] || ''
        path = book['path'] || ''
        name.downcase.include?(query) || path.downcase.include?(query)
      end
    end

    def open_book(path)
      unless File.exist?(path)
        @scanner.scan_message = 'File not found'
        @scanner.scan_status = :error
        return
      end

      begin
        Terminal.cleanup
        RecentFiles.add(path)
        reader = Reader.new(path, @config)
        reader.run
      rescue StandardError => e
        @scanner.scan_message = "Failed: #{e.message[0..30]}"
        @scanner.scan_status = :error
      ensure
        Terminal.setup
      end
    end

    def open_file_dialog
      Terminal.cleanup
      print 'Enter EPUB file path: '
      input = gets
      path = sanitize_input_path(input)

      handle_file_path(path) if path && !path.empty?

      Terminal.setup
    rescue Interrupt
      # User pressed Ctrl-C or similar while entering the file path. Restore the
      # terminal state and exit the dialog gracefully without raising.
      Terminal.setup
    rescue StandardError => e
      handle_dialog_error(e)
    end

    def sanitize_input_path(input)
      return '' unless input

      path = input.chomp.strip
      if (path.start_with?("'") && path.end_with?("'")) ||
         (path.start_with?('"') && path.end_with?('"'))
        path = path[1..-2]
      end
      path.delete('"')
    end

    def handle_file_path(path)
      if File.exist?(path) && path.downcase.end_with?('.epub')
        RecentFiles.add(path)
        reader = Reader.new(path, @config)
        reader.run
      else
        puts 'Error: Invalid file path or not an EPUB file'
        sleep 2
      end
    end

    def handle_dialog_error(error)
      puts "Error: #{error.message}"
      sleep 2
      Terminal.setup
    end

    def time_ago_in_words(time)
      return 'unknown' unless time

      seconds = Time.now - time
      format_time_ago(seconds, time)
    rescue StandardError
      'unknown'
    end

    def format_time_ago(seconds, time)
      case seconds
      when 0..59 then 'just now'
      when 60..3599 then "#{(seconds / 60).to_i}m ago"
      when 3600..86_399 then "#{(seconds / 3600).to_i}h ago"
      when 86_400..604_799 then "#{(seconds / 86_400).to_i}d ago"
      else time.strftime('%b %d')
      end
    end
  end
end
