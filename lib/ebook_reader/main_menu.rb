# frozen_string_literal: true

module EbookReader
  # Main menu (LazyVim style)
  class MainMenu
    def initialize
      @selected = 0
      @mode = :menu # :menu, :browse, :recent, :settings
      @epubs = []
      @filtered_epubs = []
      @browse_selected = 0
      @search_query = ''
      @config = Config.new
      @scan_status = :idle # :idle, :scanning, :done, :error
      @scan_message = ''
      @scan_thread = nil
      @scan_results_queue = Queue.new
    end

    def run
      Terminal.setup

      # Try to load from cache immediately
      load_cached_epubs

      # Start background scan if cache is empty or old
      start_scan if @epubs.empty?

      loop do
        # Process results from background scan
        unless @scan_results_queue.empty?
          result = @scan_results_queue.pop
          @scan_status = result[:status]
          @scan_message = result[:message]
          if result[:epubs]
            @epubs = result[:epubs]
            filter_books # Re-apply search filter with new book list
          end
        end

        draw_screen

        if (key = Terminal.get_key)
          handle_input(key)
        end

        sleep 0.02 # Prevent high CPU usage and allow screen to refresh
      end
    rescue Interrupt
      Terminal.cleanup
      puts "\nGoodbye!"
      exit 0
    rescue StandardError => e
      Terminal.cleanup
      puts "Error: #{e.message}"
      puts e.backtrace if DEBUG_MODE
      exit 1
    ensure
      begin
        @scan_thread&.kill
      rescue StandardError
        nil
      end
    end

    private

    def load_cached_epubs
      @epubs = EPUBFinder.scan_system(false) || []
      @filtered_epubs = @epubs
      @scan_status = @epubs.empty? ? :idle : :done
      @scan_message = "Loaded #{@epubs.length} books from cache" if @scan_status == :done
    rescue StandardError => e
      @scan_status = :error
      @scan_message = "Cache load failed: #{e.message}"
      @epubs = []
      @filtered_epubs = []
    end

    def start_scan(force = false)
      return if @scan_thread&.alive?

      @scan_status = :scanning
      @scan_message = 'Scanning for EPUB files...'
      @epubs = []
      @filtered_epubs = []
      @browse_selected = 0

      @scan_thread = Thread.new do
        epubs = EPUBFinder.scan_system(force) || []
        sorted_epubs = epubs.sort_by { |e| (e['name'] || '').downcase }
        @scan_results_queue.push({
                                   status: :done,
                                   epubs: sorted_epubs,
                                   message: "Found #{sorted_epubs.length} books"
                                 })
      rescue StandardError => e
        @scan_results_queue.push({
                                   status: :error,
                                   epubs: [],
                                   message: "Scan failed: #{e.message[0..50]}"
                                 })
      end
    end

    def draw_screen
      Terminal.start_frame
      height, width = Terminal.size

      case @mode
      when :menu
        draw_main_menu(height, width)
      when :browse
        draw_browse_screen(height, width)
      when :recent
        draw_recent_screen(height, width)
      when :settings
        draw_settings_screen(height, width)
      end

      Terminal.end_frame
    end

    def draw_main_menu(height, width)
      # ASCII Art Header (LazyVim style)
      logo = [
        '   _____ _                 __        _   __                __   ____                __         ',
        "  / ___/(_)___ ___  ____  / /__     / | / /___ _   _____  / /  / __ \___  ____ _____/ /__  _____",
        "  \__ \/ / __ `__ \/ __ \/ / _ \   /  |/ / __ \ | / / _ \/ /  / /_/ / _ \/ __ `/ __  / _ \/ ___/",
        ' ___/ / / / / / / /_/ / /  __/  / /|  / /_/ / |/ /  __/ /  / _, _/  __/ /_/ / /_/ /  __/ /    ',
        "/____/_/_/ /_/ /_/ .___/_/\___/  /_/ |_/\____/|___/\___/_/  /_/ |_|\___/\__,_/\__,_/\___/_/     ",
        '                /_/                                                                              '
      ]

      # Center and draw logo
      logo_start = [((height - logo.length - 15) / 2), 2].max
      logo.each_with_index do |line, i|
        col = [(width - line.length) / 2, 1].max
        Terminal.write(logo_start + i, col, Terminal::ANSI::CYAN + line + Terminal::ANSI::RESET)
      end

      # Version
      version_text = "version #{VERSION}"
      Terminal.write(logo_start + logo.length + 1, (width - version_text.length) / 2,
                     Terminal::ANSI::DIM + Terminal::ANSI::WHITE + version_text + Terminal::ANSI::RESET)

      # Menu items
      menu_items = [
        { key: 'f', icon: '', text: 'Find Book', desc: 'Browse all EPUBs' },
        { key: 'r', icon: '󰁯', text: 'Recent', desc: 'Recently opened books' },
        { key: 'o', icon: '󰷏', text: 'Open File', desc: 'Enter path manually' },
        { key: 's', icon: '', text: 'Settings', desc: 'Configure reader' },
        { key: 'q', icon: '󰿅', text: 'Quit', desc: 'Exit application' }
      ]

      menu_start = logo_start + logo.length + 5

      menu_items.each_with_index do |item, i|
        row = menu_start + (i * 2)
        next if row >= height - 2

        pointer_col = [(width / 2) - 20, 2].max
        text_col = [(width / 2) - 18, 4].max

        if i == @selected
          # Highlighted item
          Terminal.write(row, pointer_col, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
          Terminal.write(row, text_col,
                         "#{Terminal::ANSI::BRIGHT_WHITE}#{item[:icon]}  #{Terminal::ANSI::BRIGHT_YELLOW}[#{item[:key]}]#{Terminal::ANSI::BRIGHT_WHITE} #{item[:text]}#{Terminal::ANSI::GRAY} — #{item[:desc]}#{Terminal::ANSI::RESET}")
        else
          Terminal.write(row, pointer_col, '  ') # Clear pointer area
          Terminal.write(row, text_col,
                         "#{Terminal::ANSI::WHITE}#{item[:icon]}  #{Terminal::ANSI::YELLOW}[#{item[:key]}]#{Terminal::ANSI::WHITE} #{item[:text]}#{Terminal::ANSI::DIM}#{Terminal::ANSI::GRAY} — #{item[:desc]}#{Terminal::ANSI::RESET}")
        end
      end

      # Footer
      footer = 'Navigate with ↑↓ or jk • Select with Enter'
      Terminal.write(height - 1, [(width - footer.length) / 2, 1].max,
                     Terminal::ANSI::DIM + Terminal::ANSI::WHITE + footer + Terminal::ANSI::RESET)
    end

    def draw_browse_screen(height, width)
      # Header
      Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}📚 Browse Books#{Terminal::ANSI::RESET}")
      Terminal.write(1, [width - 30, 40].max, "#{Terminal::ANSI::DIM}[r] Refresh [ESC] Back#{Terminal::ANSI::RESET}")

      # Search bar
      Terminal.write(3, 2, "#{Terminal::ANSI::WHITE}Search: #{Terminal::ANSI::RESET}")
      Terminal.write(3, 10, "#{Terminal::ANSI::BRIGHT_WHITE}#{@search_query}_#{Terminal::ANSI::RESET}")

      # Status line
      status_text = case @scan_status
                    when :scanning
                      "#{Terminal::ANSI::YELLOW}⟳ #{@scan_message}#{Terminal::ANSI::RESET}"
                    when :error
                      "#{Terminal::ANSI::RED}✗ #{@scan_message}#{Terminal::ANSI::RESET}"
                    when :done
                      "#{Terminal::ANSI::GREEN}✓ #{@scan_message}#{Terminal::ANSI::RESET}"
                    else
                      ''
                    end
      Terminal.write(4, 2, status_text) unless status_text.empty?

      # Book list
      list_start = 6
      list_height = [height - 8, 1].max

      if @filtered_epubs.empty?
        if @scan_status == :scanning
          Terminal.write(height / 2, [(width - 30) / 2, 1].max,
                         "#{Terminal::ANSI::YELLOW}⟳ Scanning for books...#{Terminal::ANSI::RESET}")
          Terminal.write(height / 2 + 2, [(width - 40) / 2, 1].max,
                         "#{Terminal::ANSI::DIM}This may take a moment on first run#{Terminal::ANSI::RESET}")
        elsif @epubs.empty?
          Terminal.write(height / 2, [(width - 30) / 2, 1].max,
                         "#{Terminal::ANSI::DIM}No EPUB files found#{Terminal::ANSI::RESET}")
          Terminal.write(height / 2 + 2, [(width - 35) / 2, 1].max,
                         "#{Terminal::ANSI::DIM}Press [r] to refresh scan#{Terminal::ANSI::RESET}")
        else
          Terminal.write(height / 2, [(width - 25) / 2, 1].max,
                         "#{Terminal::ANSI::DIM}No matching books#{Terminal::ANSI::RESET}")
        end
        return
      end

      # Calculate visible range
      visible_start = [@browse_selected - list_height / 2, 0].max
      visible_end = [visible_start + list_height, @filtered_epubs.length].min

      # Adjust if at the end
      if visible_end == @filtered_epubs.length && @filtered_epubs.length > list_height
        visible_start = [visible_end - list_height, 0].max
      end

      (visible_start...visible_end).each_with_index do |idx, row|
        next if row >= list_height

        book = @filtered_epubs[idx]
        next unless book

        name = (book['name'] || 'Unknown')[0, [width - 40, 40].max]
        if idx == @browse_selected
          Terminal.write(list_start + row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
          Terminal.write(list_start + row, 4, Terminal::ANSI::BRIGHT_WHITE + name + Terminal::ANSI::RESET)
        else
          Terminal.write(list_start + row, 2, '  ') # Clear pointer area
          Terminal.write(list_start + row, 4, Terminal::ANSI::WHITE + name + Terminal::ANSI::RESET)
        end

        # Path (dimmed)
        next unless width > 60

        path = (book['dir'] || '').sub(ENV['HOME'], '~')
        path = "#{path[0, 30]}..." if path.length > 33
        Terminal.write(list_start + row, [width - 35, 45].max,
                       Terminal::ANSI::DIM + Terminal::ANSI::GRAY + path + Terminal::ANSI::RESET)
      end

      # Scroll indicator
      if @filtered_epubs.length > list_height
        scroll_pos = @filtered_epubs.length > 1 ? @browse_selected.to_f / (@filtered_epubs.length - 1) : 0
        scroll_row = list_start + (scroll_pos * (list_height - 1)).to_i
        Terminal.write(scroll_row, width - 2, "#{Terminal::ANSI::BRIGHT_CYAN}▐#{Terminal::ANSI::RESET}")
      end

      # Status bar
      Terminal.write(height - 1, 2,
                     Terminal::ANSI::DIM + "#{@filtered_epubs.length} books • " \
                       '↑↓ Navigate • Enter Open • / Search • r Refresh • ESC Back' + Terminal::ANSI::RESET)
    end

    def draw_recent_screen(height, width)
      recent = RecentFiles.load.select { |r| r && r['path'] && File.exist?(r['path']) }

      Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}🕒 Recent Books#{Terminal::ANSI::RESET}")
      Terminal.write(1, [width - 20, 60].max, "#{Terminal::ANSI::DIM}[ESC] Back#{Terminal::ANSI::RESET}")

      if recent.empty?
        Terminal.write(height / 2, [(width - 20) / 2, 1].max,
                       "#{Terminal::ANSI::DIM}No recent books#{Terminal::ANSI::RESET}")
        return
      end

      list_start = 4
      max_items = [(height - 6) / 2, 10].min

      recent.take(max_items).each_with_index do |book, i|
        row_base = list_start + i * 2
        next if row_base >= height - 2

        if i == @browse_selected
          Terminal.write(row_base, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
          Terminal.write(row_base, 4,
                         Terminal::ANSI::BRIGHT_WHITE + (book['name'] || 'Unknown') + Terminal::ANSI::RESET)
        else
          Terminal.write(row_base, 2, '  ') # Clear pointer area
          Terminal.write(row_base, 4, Terminal::ANSI::WHITE + (book['name'] || 'Unknown') + Terminal::ANSI::RESET)
        end

        # Time ago
        if book['accessed']
          time_ago = time_ago_in_words(Time.parse(book['accessed']))
          Terminal.write(row_base, [width - 20, 60].max, Terminal::ANSI::DIM + time_ago + Terminal::ANSI::RESET)
        end

        # Path
        next unless row_base + 1 < height - 2

        path = (book['path'] || '').sub(ENV['HOME'], '~')
        Terminal.write(row_base + 1, 6,
                       Terminal::ANSI::DIM + Terminal::ANSI::GRAY + path[0, width - 8] + Terminal::ANSI::RESET)
      end

      # Footer
      Terminal.write(height - 1, 2,
                     "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Open • ESC Back#{Terminal::ANSI::RESET}")
    end

    def draw_settings_screen(height, width)
      Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}⚙️  Settings#{Terminal::ANSI::RESET}")
      Terminal.write(1, [width - 20, 60].max, "#{Terminal::ANSI::DIM}[ESC] Back#{Terminal::ANSI::RESET}")

      settings = [
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
        }
      ]

      start_row = 5
      settings.each_with_index do |setting, i|
        row_base = start_row + i * 3
        next if row_base >= height - 4

        Terminal.write(row_base, 4,
                       Terminal::ANSI::YELLOW + "[#{setting[:key]}]" + Terminal::ANSI::WHITE + " #{setting[:name]}" + Terminal::ANSI::RESET)

        if row_base + 1 < height - 3
          color = setting[:action] ? Terminal::ANSI::CYAN : Terminal::ANSI::BRIGHT_GREEN
          Terminal.write(row_base + 1, 8, color + setting[:value] + Terminal::ANSI::RESET)
        end
      end

      # Show status message if any
      if @scan_message && @scan_status == :idle
        Terminal.write(start_row + settings.length * 3 + 1, 4,
                       Terminal::ANSI::YELLOW + @scan_message + Terminal::ANSI::RESET)
      end

      # Instructions
      Terminal.write(height - 3, 4,
                     "#{Terminal::ANSI::DIM}Press number keys to toggle settings#{Terminal::ANSI::RESET}")
      Terminal.write(height - 2, 4, "#{Terminal::ANSI::DIM}Changes are saved automatically#{Terminal::ANSI::RESET}")
    end

    def handle_input(key)
      case @mode
      when :menu
        handle_menu_input(key)
      when :browse
        handle_browse_input(key)
      when :recent
        handle_recent_input(key)
      when :settings
        handle_settings_input(key)
      end
    end

    def handle_menu_input(key)
      case key
      when 'q', 'Q'
        Terminal.cleanup
        exit 0
      when 'f', 'F'
        @mode = :browse
        @browse_selected = 0
        # Trigger scan if no books loaded
        start_scan if @epubs.empty? && @scan_status == :idle
      when 'r', 'R'
        @mode = :recent
        @browse_selected = 0
      when 'o', 'O'
        open_file_dialog
      when 's', 'S'
        @mode = :settings
      when 'j', "\e[B", "\eOB" # Down (handle both arrow formats)
        @selected = (@selected + 1) % 5
      when 'k', "\e[A", "\eOA" # Up
        @selected = (@selected - 1 + 5) % 5
      when "\r", "\n" # Enter
        case @selected
        when 0
          @mode = :browse
          start_scan if @epubs.empty? && @scan_status == :idle
        when 1 then @mode = :recent
        when 2 then open_file_dialog
        when 3 then @mode = :settings
        when 4
          Terminal.cleanup
          exit 0
        end
      end
    end

    def handle_browse_input(key)
      case key
      when "\e", "\x1B", 'q' # ESC or q
        @mode = :menu
      when 'r', 'R' # Refresh
        EPUBFinder.clear_cache
        start_scan(true)
      when 'j', "\e[B", "\eOB" # Down
        @browse_selected = [@browse_selected + 1, @filtered_epubs.length - 1].min if @filtered_epubs.any?
      when 'k', "\e[A", "\eOA" # Up
        @browse_selected = [@browse_selected - 1, 0].max if @filtered_epubs.any?
      when "\r", "\n" # Enter
        if @filtered_epubs[@browse_selected]
          path = @filtered_epubs[@browse_selected]['path']
          if path && File.exist?(path)
            open_book(path)
          else
            @scan_message = 'File not found'
            @scan_status = :error
          end
        end
      when '/'
        @search_query = ''
        # Clear search mode
      when "\b", "\x7F", "\x08" # Backspace variations
        if @search_query.length.positive?
          @search_query = @search_query[0...-1]
          filter_books
        end
      else
        if key && key =~ /[a-zA-Z0-9 .-]/
          @search_query += key
          filter_books
        end
      end
    end

    def handle_recent_input(key)
      recent = RecentFiles.load.select { |r| r && r['path'] && File.exist?(r['path']) }

      case key
      when "\e", "\x1B", 'q'
        @mode = :menu
      when 'j', "\e[B", "\eOB"
        @browse_selected = [@browse_selected + 1, recent.length - 1].min if recent.any?
      when 'k', "\e[A", "\eOA"
        @browse_selected = [@browse_selected - 1, 0].max if recent.any?
      when "\r", "\n"
        book = recent[@browse_selected]
        open_book(book['path']) if book && book['path'] && File.exist?(book['path'])
      end
    end

    def handle_settings_input(key)
      case key
      when "\e", "\x1B", 'q'
        @mode = :menu
        @config.save
      when '1'
        @config.view_mode = @config.view_mode == :split ? :single : :split
        @config.save
      when '2'
        @config.show_page_numbers = !@config.show_page_numbers
        @config.save
      when '3'
        modes = %i[compact normal relaxed]
        current = modes.index(@config.line_spacing) || 1
        @config.line_spacing = modes[(current + 1) % 3]
        @config.save
      when '4'
        @config.highlight_quotes = !@config.highlight_quotes
        @config.save
      when '5'
        EPUBFinder.clear_cache
        @epubs = []
        @filtered_epubs = []
        @scan_status = :idle
        @scan_message = "Cache cleared! Use 'Find Book' to rescan"
      end
    end

    def filter_books
      if @search_query.empty?
        @filtered_epubs = @epubs
      else
        query = @search_query.downcase
        @filtered_epubs = @epubs.select do |book|
          name = book['name'] || ''
          path = book['path'] || ''
          name.downcase.include?(query) || path.downcase.include?(query)
        end
      end
      @browse_selected = 0
    end

    def open_book(path)
      unless File.exist?(path)
        @scan_message = 'File not found'
        @scan_status = :error
        return
      end

      begin
        Terminal.cleanup
        RecentFiles.add(path)

        # Launch reader with the book
        reader = Reader.new(path, @config)
        reader.run
      rescue StandardError => e
        # Show error and return to menu
        @scan_message = "Failed: #{e.message[0..30]}"
        @scan_status = :error
      ensure
        # Return to menu after reading
        Terminal.setup
      end
    end

    def open_file_dialog
      Terminal.cleanup
      print 'Enter EPUB file path: '
      path = gets&.chomp

      if path && !path.empty?
        if File.exist?(path) && path.downcase.end_with?('.epub')
          RecentFiles.add(path)
          config = Config.new
          reader = Reader.new(path, config)
          reader.run
        else
          puts 'Error: Invalid file path or not an EPUB file'
          sleep 2
        end
      end

      Terminal.setup
    rescue StandardError => e
      puts "Error: #{e.message}"
      sleep 2
      Terminal.setup
    end

    def time_ago_in_words(time)
      return 'unknown' unless time

      seconds = Time.now - time
      case seconds
      when 0..59 then 'just now'
      when 60..3599 then "#{(seconds / 60).to_i}m ago"
      when 3600..86_399 then "#{(seconds / 3600).to_i}h ago"
      when 86_400..604_799 then "#{(seconds / 86_400).to_i}d ago"
      else time.strftime('%b %d')
      end
    rescue StandardError
      'unknown'
    end
  end
end
