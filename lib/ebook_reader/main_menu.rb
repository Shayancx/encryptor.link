# frozen_string_literal: true

require_relative 'ui/main_menu_renderer'
require_relative 'ui/browse_screen'
require_relative 'ui/recent_item_renderer'
require_relative 'ui/screens/menu_screen'
require_relative 'ui/screens/settings_screen'
require_relative 'ui/screens/recent_screen'
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
      @menu_screen = UI::Screens::MenuScreen.new(@renderer, @selected)
      @settings_screen = UI::Screens::SettingsScreen.new(@config, @scanner)
      @recent_screen = UI::Screens::RecentScreen.new(self)
      @input_handler = Services::MainMenuInputHandler.new(self)
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
        @input_handler.handle_input(Terminal.read_key)
        sleep 0.02
      end
    end

    def process_scan_results
      return unless (epubs = @scanner.process_results)

      @scanner.epubs = epubs
      filter_books
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
      @menu_screen.selected = @selected
      @menu_screen.draw(height, width)
    end

    def draw_browse_screen(height, width)
      @browse_screen.render_header(width)
      @browse_screen.render_search_bar(@search_query)
      @browse_screen.render_status(@scanner.scan_status, @scanner.scan_message)

      if @filtered_epubs.empty?
        @browse_screen.render_empty_state(height, width, @scanner.scan_status,
                                          @scanner.epubs.empty?)
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
      return unless @filtered_epubs.length > list_height

      render_scroll_indicator(list_start, list_height,
                              width)
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
      @recent_screen.selected = @browse_selected
      @recent_screen.draw(height, width)
    end

    def draw_settings_screen(height, width)
      @settings_screen.draw(height, width)
    end

    def handle_input(key)
      @input_handler.handle_input(key)
    end

    def handle_menu_input(key)
      @input_handler.handle_menu_input(key)
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
      @input_handler.handle_browse_input(key)
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
      @input_handler.send(:handle_backspace)
    end

    def searchable_key?(key)
      @input_handler.searchable_key?(key)
    end

    def add_to_search(key)
      @input_handler.send(:add_to_search, key)
    end

    def handle_recent_input(key)
      @input_handler.handle_recent_input(key)
    end

    def handle_settings_input(key)
      @input_handler.handle_settings_input(key)
    end

    def handle_setting_change(key)
      @input_handler.handle_setting_change(key)
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
        Infrastructure::Logger.error('Failed to open book', error: e.message, path:)
        @scanner.scan_message = "Failed: #{e.class}: #{e.message[0, 60]}"
        @scanner.scan_status = :error
        puts e.backtrace.join("\n") if EPUBFinder::DEBUG_MODE
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
      path = path.delete('"')
      File.expand_path(path)
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

    def load_recent_books
      books = @recent_screen.send(:load_recent_books)
      @browse_selected = @recent_screen.selected
      books
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
