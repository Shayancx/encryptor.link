# frozen_string_literal: true

module EbookReader
  # Enhanced reader with single/split view
  class Reader
    def initialize(epub_path, config = Config.new)
      @path = epub_path
      @doc = nil
      @config = config
      @current_chapter = 0
      @left_page = 0
      @right_page = 0
      @single_page = 0
      @running = true
      @mode = :read # :read, :help, :toc, :bookmarks
      @toc_selected = 0
      @bookmarks = []
      @bookmark_selected = 0
      @message = nil

      # For global page counting
      @page_map = []
      @total_pages = 0
      @last_width = 0
      @last_height = 0

      # Try to load the EPUB
      begin
        @doc = EPUBDocument.new(epub_path)
      rescue StandardError => e
        # If loading fails, create a simple error document
        @doc = create_error_document(e.message)
      end

      load_progress
      load_bookmarks
    end

    def run
      Terminal.setup

      while @running
        draw_screen

        if (key = Terminal.get_key)
          process_input(key)
        end

        sleep 0.02 # Prevent high CPU usage
      end
    ensure
      Terminal.cleanup
    end

    private

    def update_page_map(width, height)
      return if @doc.nil?

      # Determine layout for the current view mode to calculate pages
      col_width, content_height = get_layout_metrics(width, height)
      actual_height = adjust_for_line_spacing(content_height)
      return if actual_height <= 0

      @page_map = @doc.chapters.map do |chapter|
        wrapped = wrap_lines(chapter[:lines] || [], col_width)
        (wrapped.size.to_f / actual_height).ceil
      end

      @total_pages = @page_map.sum
      @last_width = width
      @last_height = height
    end

    def get_layout_metrics(width, height)
      if @config.view_mode == :split
        col_width = [(width - 3) / 2, 20].max - 2
        content_height = [height - 4, 1].max
      else # :single
        col_width = [[(width * 0.9).to_i, 120].min, 30].max
        content_height = [height - 2, 1].max
      end
      [col_width, content_height]
    end

    def load_progress
      progress = ProgressManager.load(@path)
      return unless progress

      @current_chapter = progress['chapter'] || 0
      line_offset = progress['line_offset'] || 0

      @current_chapter = 0 if @current_chapter >= @doc.chapter_count

      @single_page = line_offset
      @left_page = line_offset
      @right_page = line_offset
    end

    def save_progress
      return unless @path && @doc

      line_offset = @config.view_mode == :split ? @left_page : @single_page
      ProgressManager.save(@path, @current_chapter, line_offset)
    end

    def load_bookmarks
      @bookmarks = BookmarkManager.get(@path)
    end

    def add_bookmark
      line_offset = @config.view_mode == :split ? @left_page : @single_page

      height, width = Terminal.size
      col_width, = get_layout_metrics(width, height)

      chapter = @doc.get_chapter(@current_chapter)
      return unless chapter

      wrapped = wrap_lines(chapter[:lines] || [], col_width)
      text_snippet = wrapped[line_offset] || 'Bookmark'
      text_snippet = text_snippet.strip[0, 50]

      BookmarkManager.add(@path, @current_chapter, line_offset, text_snippet)
      load_bookmarks # Refresh
      set_message('Bookmark added!')
    end

    def set_message(text, duration = 2)
      @message = text
      Thread.new do
        sleep duration
        @message = nil
      end
    end

    def create_error_document(error_msg)
      # Create a fake document with error information
      doc = Object.new
      doc.define_singleton_method(:title) { 'Error Loading EPUB' }
      doc.define_singleton_method(:language) { 'en_US' }
      doc.define_singleton_method(:chapter_count) { 1 }
      doc.define_singleton_method(:chapters) { [{ title: 'Error', lines: [] }] }
      doc.define_singleton_method(:get_chapter) do |_idx|
        {
          number: '1',
          title: 'Error',
          lines: [
            'Failed to load EPUB file:',
            '',
            error_msg,
            '',
            'Possible causes:',
            '- The file might be corrupted',
            '- The file might not be a valid EPUB',
            '- The file might be password protected',
            '',
            "Press 'q' to return to the menu"
          ]
        }
      end
      doc
    end

    def draw_screen
      Terminal.start_frame
      height, width = Terminal.size

      # Recalculate page map if terminal was resized or view mode changed
      update_page_map(width, height) if width != @last_width || height != @last_height

      # Header line
      draw_header(width)

      # Main content or other modes
      case @mode
      when :help
        draw_help_screen(height, width)
      when :toc
        draw_toc_screen(height, width)
      when :bookmarks
        draw_bookmarks_screen(height, width)
      else # :read
        if @config.view_mode == :split
          draw_split_screen(height, width)
        else
          draw_single_screen(height, width)
        end
      end

      # Footer lines
      draw_footer(height, width)

      # Message overlay
      if @message
        msg_len = @message.length
        Terminal.write(height / 2, (width - msg_len) / 2,
                       "#{Terminal::ANSI::BG_DARK}#{Terminal::ANSI::BRIGHT_YELLOW} #{@message} #{Terminal::ANSI::RESET}")
      end

      Terminal.end_frame
    end

    def draw_header(width)
      # In single view mode, only show the book title. Otherwise, show full header.
      if @config.view_mode == :single && @mode == :read
        title_text = @doc.title
        Terminal.write(1, 2, Terminal::ANSI::WHITE + title_text[0, width - 4] + Terminal::ANSI::RESET)
      else
        # Original header for split view, help, toc, etc.
        title_text = 'Simple Novel Reader'
        Terminal.write(1, 1, Terminal::ANSI::WHITE + title_text + Terminal::ANSI::RESET)
        right_text = 'q:Quit ?:Help t:ToC B:Bookmarks'
        Terminal.write(1, [width - right_text.length + 1, 1].max,
                       Terminal::ANSI::WHITE + right_text + Terminal::ANSI::RESET)
      end
    end

    def draw_split_screen(height, width)
      # Get current chapter
      chapter = @doc.get_chapter(@current_chapter)
      return unless chapter

      col_width, content_height = get_layout_metrics(width, height)

      # Add line spacing
      content_height = adjust_for_line_spacing(content_height)

      # Wrap content to column width
      wrapped = wrap_lines(chapter[:lines] || [], col_width)

      # Chapter indicator above left column
      chapter_info = "[#{@current_chapter + 1}] #{chapter[:title] || 'Unknown'}"
      Terminal.write(2, 1, Terminal::ANSI::BLUE + chapter_info[0, width - 2] + Terminal::ANSI::RESET)

      # Draw left column
      draw_column(3, 1, col_width, content_height, wrapped, @left_page, true)

      # Draw divider
      (3...[height - 1, 4].max).each do |row|
        Terminal.write(row, col_width + 3, "#{Terminal::ANSI::GRAY}│#{Terminal::ANSI::RESET}")
      end

      # Draw right column
      draw_column(3, col_width + 5, col_width, content_height, wrapped, @right_page, false)
    end

    def draw_single_screen(height, width)
      chapter = @doc.get_chapter(@current_chapter)
      return unless chapter

      col_width, content_height = get_layout_metrics(width, height)
      col_start = [(width - col_width) / 2, 1].max

      # Add line spacing
      content_height = adjust_for_line_spacing(content_height)

      # Wrap content
      wrapped = wrap_lines(chapter[:lines] || [], col_width)

      # Draw content, starting from row 2, no internal page number
      draw_column(2, col_start, col_width, content_height, wrapped, @single_page, false)
    end

    def draw_column(start_row, start_col, width, height, lines, offset, show_page_num)
      # Safety checks
      return if lines.nil? || lines.empty?
      return if width < 10 || height < 1

      # Calculate what to show
      actual_height = height

      if @config.line_spacing == :relaxed
        actual_height = [height / 2, 1].max
      elsif @config.line_spacing == :compact
        actual_height = height
      end

      end_offset = [offset + actual_height, lines.size].min

      # Draw each line
      line_count = 0
      (offset...end_offset).each do |line_idx|
        break if line_count >= actual_height

        line = lines[line_idx] || ''

        # Calculate row with line spacing
        row = start_row + line_count
        row = start_row + (line_count * 2) if @config.line_spacing == :relaxed

        # Skip if row is out of bounds
        next if row >= Terminal.size[0] - 2

        # Highlight certain phrases if enabled
        if @config.highlight_quotes && line =~ /"[^"]+"|'[^']+'|Chinese poets|philosophers|Taoyuen-ming|celebrated|fragrance|plum-blossoms|Linwosing|Chowmushih/
          display_line = line.gsub(/(Chinese poets|philosophers|Taoyuen-ming|celebrated|fragrance|plum-blossoms|Linwosing|Chowmushih)/) do |match|
            Terminal::ANSI::CYAN + match + Terminal::ANSI::WHITE
          end
          display_line = display_line.gsub(/("[^"]+")|('[^']+')/) do |match|
            Terminal::ANSI::ITALIC + match + Terminal::ANSI::RESET + Terminal::ANSI::WHITE
          end
          Terminal.write(row, start_col, Terminal::ANSI::WHITE + display_line[0, width] + Terminal::ANSI::RESET)
        else
          Terminal.write(row, start_col, Terminal::ANSI::WHITE + line[0, width] + Terminal::ANSI::RESET)
        end

        line_count += 1
      end

      # Show page number if enabled
      return unless @config.show_page_numbers && show_page_num && lines.size.positive? && actual_height.positive?

      page_num = (offset / actual_height) + 1
      total_pages = [(lines.size.to_f / actual_height).ceil, 1].max
      page_text = "#{page_num}/#{total_pages}"
      page_row = start_row + height - 1
      return unless page_row < Terminal.size[0] - 2

      Terminal.write(page_row, [start_col + width - page_text.length, start_col].max,
                     Terminal::ANSI::DIM + Terminal::ANSI::GRAY + page_text + Terminal::ANSI::RESET)
    end

    def draw_footer(height, width)
      if @config.view_mode == :single && @mode == :read
        # Use the pre-calculated page map for global page numbers
        if @config.show_page_numbers && @total_pages.positive?
          _, content_height = get_layout_metrics(width, height)
          actual_height = adjust_for_line_spacing(content_height)
          return if actual_height <= 0

          # Page number within the current chapter
          page_in_chapter = (@single_page / actual_height) + 1

          # Pages from all previous chapters
          pages_before = @page_map[0...@current_chapter].sum

          current_global_page = pages_before + page_in_chapter

          page_text = "#{current_global_page} / #{@total_pages}"
          Terminal.write(height, 2, Terminal::ANSI::DIM + Terminal::ANSI::GRAY + page_text + Terminal::ANSI::RESET)
        end
      else
        # Original footer for other views
        footer1 = [height - 1, 3].max

        left_prog = "[#{@current_chapter + 1}/#{@doc.chapter_count}]"
        Terminal.write(footer1, 1, Terminal::ANSI::BLUE + left_prog + Terminal::ANSI::RESET)

        mode_text = @config.view_mode == :split ? '[SPLIT]' : '[SINGLE]'
        Terminal.write(footer1, [(width / 2) - 10, 20].max, Terminal::ANSI::YELLOW + mode_text + Terminal::ANSI::RESET)

        right_prog = "L#{@config.line_spacing.to_s[0]} B#{@bookmarks.count}"
        Terminal.write(footer1, [width - right_prog.length - 1, 40].max,
                       Terminal::ANSI::BLUE + right_prog + Terminal::ANSI::RESET)

        footer2 = height
        if footer2 > 3
          Terminal.write(footer2, 1, Terminal::ANSI::WHITE + "[#{@doc.title[0, width - 15]}]" + Terminal::ANSI::RESET)
          Terminal.write(footer2, [width - 10, 50].max,
                         Terminal::ANSI::WHITE + "[#{@doc.language}]" + Terminal::ANSI::RESET)
        end
      end
    end

    def draw_help_screen(height, width)
      help_lines = [
        '',
        'Navigation Keys:',
        '  j / ↓     Scroll down',
        '  k / ↑     Scroll up',
        '  l / →     Next page',
        '  h / ←     Previous page',
        '  SPACE     Next page',
        '  n         Next chapter',
        '  p         Previous chapter',
        '  g         Go to beginning of chapter',
        '  G         Go to end of chapter',
        '',
        'View Options:',
        '  v         Toggle split/single view',
        '  + / -     Adjust line spacing',
        '',
        'Features:',
        '  t         Show Table of Contents',
        '  b         Add a bookmark',
        '  B         Show bookmarks',
        '',
        'Other Keys:',
        '  ?         Show/hide this help',
        '  q         Quit to menu',
        '  Q         Quit application',
        '',
        '',
        'Press any key to return to reading...'
      ]

      # Center the help text
      start_row = [(height - help_lines.size) / 2, 1].max

      help_lines.each_with_index do |line, idx|
        row = start_row + idx
        break if row >= height - 2

        col = [(width - line.length) / 2, 1].max
        Terminal.write(row, col, Terminal::ANSI::WHITE + line + Terminal::ANSI::RESET)
      end
    end

    def draw_toc_screen(height, width)
      Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}📖 Table of Contents#{Terminal::ANSI::RESET}")
      Terminal.write(1, [width - 30, 40].max, "#{Terminal::ANSI::DIM}[t/ESC] Back to Reading#{Terminal::ANSI::RESET}")

      list_start = 4
      list_height = height - 6

      chapters = @doc.chapters
      return if chapters.empty?

      visible_start = [@toc_selected - list_height / 2, 0].max
      visible_end = [visible_start + list_height, chapters.length].min

      (visible_start...visible_end).each_with_index do |idx, row|
        chapter = chapters[idx]
        line = "#{idx + 1}. #{chapter[:title] || 'Untitled'}"

        if idx == @toc_selected
          Terminal.write(list_start + row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
          Terminal.write(list_start + row, 4, Terminal::ANSI::BRIGHT_WHITE + line[0, width - 6] + Terminal::ANSI::RESET)
        else
          Terminal.write(list_start + row, 4, Terminal::ANSI::WHITE + line[0, width - 6] + Terminal::ANSI::RESET)
        end
      end

      Terminal.write(height - 1, 2,
                     "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Jump • t/ESC Back#{Terminal::ANSI::RESET}")
    end

    def draw_bookmarks_screen(height, width)
      Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}🔖 Bookmarks#{Terminal::ANSI::RESET}")
      Terminal.write(1, [width - 40, 40].max, "#{Terminal::ANSI::DIM}[B/ESC] Back [d] Delete#{Terminal::ANSI::RESET}")

      if @bookmarks.empty?
        Terminal.write(height / 2, (width - 20) / 2, "#{Terminal::ANSI::DIM}No bookmarks yet.#{Terminal::ANSI::RESET}")
        Terminal.write(height / 2 + 1, (width - 30) / 2,
                       "#{Terminal::ANSI::DIM}Press 'b' while reading to add one.#{Terminal::ANSI::RESET}")
        return
      end

      list_start = 4
      list_height = (height - 6) / 2

      visible_start = [@bookmark_selected - list_height / 2, 0].max
      visible_end = [visible_start + list_height, @bookmarks.length].min

      (visible_start...visible_end).each_with_index do |idx, row_idx|
        bookmark = @bookmarks[idx]
        chapter_title = @doc.get_chapter(bookmark['chapter'])&.[](:title) || "Chapter #{bookmark['chapter'] + 1}"
        line1 = "Ch. #{bookmark['chapter'] + 1}: #{chapter_title}"
        line2 = "  > #{bookmark['text']}"

        row = list_start + row_idx * 2
        if idx == @bookmark_selected
          Terminal.write(row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
          Terminal.write(row, 4, Terminal::ANSI::BRIGHT_WHITE + line1[0, width - 6] + Terminal::ANSI::RESET)
          Terminal.write(row + 1, 4,
                         Terminal::ANSI::ITALIC + Terminal::ANSI::GRAY + line2[0, width - 6] + Terminal::ANSI::RESET)
        else
          Terminal.write(row, 4, Terminal::ANSI::WHITE + line1[0, width - 6] + Terminal::ANSI::RESET)
          Terminal.write(row + 1, 4,
                         Terminal::ANSI::DIM + Terminal::ANSI::GRAY + line2[0, width - 6] + Terminal::ANSI::RESET)
        end
      end

      Terminal.write(height - 1, 2,
                     "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Jump • d Delete • B/ESC Back#{Terminal::ANSI::RESET}")
    end

    def adjust_for_line_spacing(height)
      case @config.line_spacing
      when :compact
        height
      when :relaxed
        [height / 2, 1].max
      else
        [(height * 0.8).to_i, 1].max
      end
    end

    def wrap_lines(lines, width)
      return [] if lines.nil? || width < 10

      wrapped = []

      lines.each do |line|
        next if line.nil?

        # Handle empty lines
        if line.strip.empty?
          wrapped << ''
          next
        end

        # Word wrap long lines
        words = line.split(/\s+/)
        current = ''

        words.each do |word|
          next if word.nil?

          if current.empty?
            current = word
          elsif current.length + 1 + word.length <= width
            current += " #{word}"
          else
            wrapped << current
            current = word
          end
        end

        wrapped << current unless current.empty?
      end

      wrapped
    end

    def process_input(key)
      return unless key

      # Handle mode-specific inputs first
      case @mode
      when :help
        @mode = :read
        return
      when :toc
        handle_toc_input(key)
        return
      when :bookmarks
        handle_bookmarks_input(key)
        return
      end

      # Get dimensions for calculations
      height, width = Terminal.size
      col_width, content_height = get_layout_metrics(width, height)

      content_height = adjust_for_line_spacing(content_height)

      chapter = @doc.get_chapter(@current_chapter)
      return unless chapter

      wrapped = wrap_lines(chapter[:lines] || [], col_width)
      max_page = [wrapped.size - content_height, 0].max

      case key
      when 'q'
        save_progress
        @running = false

      when 'Q'
        save_progress
        Terminal.cleanup
        exit 0

      when '?'
        @mode = :help

      when 't', 'T'
        @mode = :toc
        @toc_selected = @current_chapter

      when 'b'
        add_bookmark

      when 'B'
        @mode = :bookmarks
        @bookmark_selected = 0

      when 'v', 'V'
        @config.view_mode = @config.view_mode == :split ? :single : :split
        @config.save
        # Force page map recalculation on next draw
        @last_width = 0
        @last_height = 0
        reset_pages

      when '+'
        modes = %i[compact normal relaxed]
        current = modes.index(@config.line_spacing) || 1
        if current < 2
          @config.line_spacing = modes[current + 1]
          @config.save
          @last_width = 0 # Recalculate pages
        end

      when '-'
        modes = %i[compact normal relaxed]
        current = modes.index(@config.line_spacing) || 1
        if current.positive?
          @config.line_spacing = modes[current - 1]
          @config.save
          @last_width = 0 # Recalculate pages
        end

      when 'j', "\e[B", "\eOB" # Down arrow
        if @config.view_mode == :split
          @left_page = [@left_page + 1, max_page].min
          @right_page = [@right_page + 1, max_page].min
        else
          @single_page = [@single_page + 1, max_page].min
        end

      when 'k', "\e[A", "\eOA" # Up arrow
        if @config.view_mode == :split
          @left_page = [@left_page - 1, 0].max
          @right_page = [@right_page - 1, 0].max
        else
          @single_page = [@single_page - 1, 0].max
        end

      when 'l', ' ', "\e[C", "\eOC" # Right arrow or space
        # Next page
        if @config.view_mode == :split
          if @right_page < max_page
            @left_page = @right_page
            @right_page = [@right_page + content_height, max_page].min
          elsif @current_chapter < @doc.chapter_count - 1
            next_chapter
          end
        elsif @single_page < max_page
          @single_page = [@single_page + content_height, max_page].min
        elsif @current_chapter < @doc.chapter_count - 1
          next_chapter
        end

      when 'h', "\e[D", "\eOD" # Left arrow
        # Previous page
        if @config.view_mode == :split
          if @left_page.positive?
            @right_page = @left_page
            @left_page = [@left_page - content_height, 0].max
          elsif @current_chapter.positive?
            prev_chapter(true)
          end
        elsif @single_page.positive?
          @single_page = [@single_page - content_height, 0].max
        elsif @current_chapter.positive?
          prev_chapter(true)
        end

      when 'n', 'N'
        next_chapter if @current_chapter < @doc.chapter_count - 1

      when 'p', 'P'
        prev_chapter if @current_chapter.positive?

      when 'g' # Beginning
        reset_pages

      when 'G' # End
        if @config.view_mode == :split
          @right_page = max_page
          @left_page = [max_page - content_height, 0].max
        else
          @single_page = max_page
        end
      end
    end

    def handle_toc_input(key)
      case key
      when 't', 'T', "\e", "\x1B", 'q'
        @mode = :read
      when 'j', "\e[B", "\eOB"
        @toc_selected = [@toc_selected + 1, @doc.chapter_count - 1].min
      when 'k', "\e[A", "\eOA"
        @toc_selected = [@toc_selected - 1, 0].max
      when "\r", "\n"
        @current_chapter = @toc_selected
        reset_pages
        save_progress
        @mode = :read
      end
    end

    def handle_bookmarks_input(key)
      return if @bookmarks.empty? && !['B', "\e", "\x1B", 'q'].include?(key)

      case key
      when 'B', "\e", "\x1B", 'q'
        @mode = :read
      when 'j', "\e[B", "\eOB"
        @bookmark_selected = [@bookmark_selected + 1, @bookmarks.length - 1].min
      when 'k', "\e[A", "\eOA"
        @bookmark_selected = [@bookmark_selected - 1, 0].max
      when "\r", "\n"
        bookmark = @bookmarks[@bookmark_selected]
        if bookmark
          @current_chapter = bookmark['chapter']
          @single_page = bookmark['line_offset']
          @left_page = bookmark['line_offset']
          @right_page = bookmark['line_offset']
          save_progress
          @mode = :read
        end
      when 'd', 'D'
        bookmark = @bookmarks[@bookmark_selected]
        if bookmark
          BookmarkManager.delete(@path, bookmark)
          load_bookmarks # Refresh
          @bookmark_selected = [@bookmark_selected, @bookmarks.length - 1].min if @bookmarks.any?
          set_message('Bookmark deleted!')
        end
      end
    end

    def reset_pages
      @left_page = 0
      @right_page = 0
      @single_page = 0
    end

    def next_chapter
      @current_chapter += 1
      reset_pages
      save_progress
    end

    def prev_chapter(go_to_end = false)
      @current_chapter -= 1

      if go_to_end
        # Go to end of previous chapter
        chapter = @doc.get_chapter(@current_chapter)
        if chapter && chapter[:lines]
          height, width = Terminal.size
          col_width, content_height = get_layout_metrics(width, height)
          content_height = adjust_for_line_spacing(content_height)
          wrapped = wrap_lines(chapter[:lines], col_width)
          max_page = [wrapped.size - content_height, 0].max

          if @config.view_mode == :split
            @right_page = max_page
            @left_page = [max_page - content_height, 0].max
          else
            @single_page = max_page
          end
        end
      else
        reset_pages
      end
    end
  end
end
