# frozen_string_literal: true

require_relative 'helpers/reader_helpers'
require_relative 'ui/reader_renderer'
require_relative 'concerns/input_handler'

module EbookReader
  # Enhanced reader with single/split view
  class Reader
    include Helpers::ReaderHelpers
    include Concerns::InputHandler

    def initialize(epub_path, config = Config.new)
      @path = epub_path
      @config = config
      @renderer = UI::ReaderRenderer.new(@config)
      initialize_state
      load_document
      load_data
    end

    def run
      Terminal.setup
      main_loop
    ensure
      Terminal.cleanup
    end

    private

    def initialize_state
      @current_chapter = 0
      @left_page = 0
      @right_page = 0
      @single_page = 0
      @running = true
      @mode = :read
      @toc_selected = 0
      @bookmarks = []
      @bookmark_selected = 0
      @message = nil
      @page_map = []
      @total_pages = 0
      @last_width = 0
      @last_height = 0
    end

    def load_document
      @doc = EPUBDocument.new(@path)
    rescue StandardError => e
      @doc = create_error_document(e.message)
    end

    def load_data
      load_progress
      load_bookmarks
    end

    def main_loop
      while @running
        draw_screen
        key = Terminal.read_key
        process_input(key) if key
        sleep 0.02
      end
    end

    def update_page_map(width, height)
      return if @doc.nil?

      col_width, content_height = get_layout_metrics(width, height)
      actual_height = adjust_for_line_spacing(content_height)
      return if actual_height <= 0

      calculate_page_map(col_width, actual_height)
      @last_width = width
      @last_height = height
    end

    def calculate_page_map(col_width, actual_height)
      @page_map = @doc.chapters.map do |chapter|
        wrapped = wrap_lines(chapter[:lines] || [], col_width)
        (wrapped.size.to_f / actual_height).ceil
      end
      @total_pages = @page_map.sum
    end

    def get_layout_metrics(width, height)
      if @config.view_mode == :split
        col_width = [(width - 3) / 2, 20].max - 2
        content_height = [height - 4, 1].max
      else
        col_width = (width * 0.9).to_i.clamp(30, 120)
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

      self.page_offsets = line_offset
    end

    def page_offsets=(offset)
      @single_page = offset
      @left_page = offset
      @right_page = offset
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
      chapter = @doc.get_chapter(@current_chapter)
      return unless chapter

      text_snippet = extract_bookmark_text(chapter, line_offset)
      BookmarkManager.add(@path, @current_chapter, line_offset, text_snippet)
      load_bookmarks
      set_message('Bookmark added!')
    end

    def extract_bookmark_text(chapter, line_offset)
      height, width = Terminal.size
      col_width, = get_layout_metrics(width, height)
      wrapped = wrap_lines(chapter[:lines] || [], col_width)
      text = wrapped[line_offset] || 'Bookmark'
      text.strip[0, 50]
    end

    def set_message(text, duration = 2)
      @message = text
      Thread.new do
        sleep duration
        @message = nil
      end
    end

    def create_error_document(error_msg)
      doc = Object.new
      doc.define_singleton_method(:title) { 'Error Loading EPUB' }
      doc.define_singleton_method(:language) { 'en_US' }
      doc.define_singleton_method(:chapter_count) { 1 }
      doc.define_singleton_method(:chapters) { [{ title: 'Error', lines: [] }] }
      doc.define_singleton_method(:get_chapter) do |_idx|
        {
          number: '1',
          title: 'Error',
          lines: build_error_lines(error_msg)
        }
      end
      doc
    end

    def build_error_lines(error_msg)
      [
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
    end

    def draw_screen
      Terminal.start_frame
      height, width = Terminal.size

      update_page_map(width, height) if size_changed?(width, height)

      @renderer.render_header(@doc, width, @config.view_mode, @mode)
      draw_content(height, width)
      draw_footer(height, width)
      draw_message(height, width) if @message

      Terminal.end_frame
    end

    def size_changed?(width, height)
      width != @last_width || height != @last_height
    end

    def draw_content(height, width)
      case @mode
      when :help then draw_help_screen(height, width)
      when :toc then draw_toc_screen(height, width)
      when :bookmarks then draw_bookmarks_screen(height, width)
      else draw_reading_content(height, width)
      end
    end

    def draw_reading_content(height, width)
      if @config.view_mode == :split
        draw_split_screen(height, width)
      else
        draw_single_screen(height, width)
      end
    end

    def draw_footer(height, width)
      pages = calculate_current_pages(height, width)
      @renderer.render_footer(height, width, @doc, @current_chapter, pages,
                              @config.view_mode, @mode, @config.line_spacing, @bookmarks)
    end

    def calculate_current_pages(height, width)
      return { current: 0, total: 0 } unless @config.show_page_numbers && @total_pages.positive?

      _, content_height = get_layout_metrics(width, height)
      actual_height = adjust_for_line_spacing(content_height)
      return { current: 0, total: 0 } if actual_height <= 0

      page_in_chapter = (@single_page / actual_height) + 1
      pages_before = @page_map[0...@current_chapter].sum
      current_global_page = pages_before + page_in_chapter

      { current: current_global_page, total: @total_pages }
    end

    def draw_message(height, width)
      msg_len = @message.length
      Terminal.write(height / 2, (width - msg_len) / 2,
                     "#{Terminal::ANSI::BG_DARK}#{Terminal::ANSI::BRIGHT_YELLOW} #{@message} " \
                     "#{Terminal::ANSI::RESET}")
    end

    def draw_split_screen(height, width)
      chapter = @doc.get_chapter(@current_chapter)
      return unless chapter

      col_width, content_height = get_layout_metrics(width, height)
      content_height = adjust_for_line_spacing(content_height)
      wrapped = wrap_lines(chapter[:lines] || [], col_width)

      draw_chapter_info(chapter, width)
      draw_split_columns(wrapped, col_width, content_height, height)
    end

    def draw_chapter_info(chapter, width)
      chapter_info = "[#{@current_chapter + 1}] #{chapter[:title] || 'Unknown'}"
      Terminal.write(2, 1, Terminal::ANSI::BLUE + chapter_info[0, width - 2] + Terminal::ANSI::RESET)
    end

    def draw_split_columns(wrapped, col_width, content_height, height)
      draw_column(3, 1, col_width, content_height, wrapped, @left_page, true)
      draw_divider(height, col_width)
      draw_column(3, col_width + 5, col_width, content_height, wrapped, @right_page, false)
    end

    def draw_divider(height, col_width)
      (3...[height - 1, 4].max).each do |row|
        Terminal.write(row, col_width + 3, "#{Terminal::ANSI::GRAY}│#{Terminal::ANSI::RESET}")
      end
    end

    def draw_single_screen(height, width)
      chapter = @doc.get_chapter(@current_chapter)
      return unless chapter

      col_width, content_height = get_layout_metrics(width, height)
      col_start = [(width - col_width) / 2, 1].max
      content_height = adjust_for_line_spacing(content_height)
      wrapped = wrap_lines(chapter[:lines] || [], col_width)

      draw_column(2, col_start, col_width, content_height, wrapped, @single_page, false)
    end

    def draw_column(start_row, start_col, width, height, lines, offset, show_page_num)
      return if invalid_column_params?(lines, width, height)

      actual_height = calculate_actual_height(height)
      end_offset = [offset + actual_height, lines.size].min

      draw_lines(lines, offset, end_offset, start_row, start_col, width, actual_height)
      draw_page_number(start_row, start_col, width, height, offset, actual_height, lines) if show_page_num
    end

    def invalid_column_params?(lines, width, height)
      lines.nil? || lines.empty? || width < 10 || height < 1
    end

    def calculate_actual_height(height)
      case @config.line_spacing
      when :relaxed
        [height / 2, 1].max
      else
        height
      end
    end

    def draw_lines(lines, start_offset, end_offset, start_row, start_col, width, actual_height)
      line_count = 0
      (start_offset...end_offset).each do |line_idx|
        break if line_count >= actual_height

        line = lines[line_idx] || ''
        row = calculate_row(start_row, line_count)

        next if row >= Terminal.size[0] - 2

        draw_line(line, row, start_col, width)
        line_count += 1
      end
    end

    def calculate_row(start_row, line_count)
      if @config.line_spacing == :relaxed
        start_row + (line_count * 2)
      else
        start_row + line_count
      end
    end

    def draw_line(line, row, start_col, width)
      if should_highlight_line?(line)
        draw_highlighted_line(line, row, start_col, width)
      else
        Terminal.write(row, start_col, Terminal::ANSI::WHITE + line[0, width] + Terminal::ANSI::RESET)
      end
    end

    def should_highlight_line?(line)
      @config.highlight_quotes &&
        line =~ /"[^"]+"|'[^']+'|Chinese poets|philosophers|Taoyuen-ming|celebrated|fragrance|plum-blossoms|Linwosing|Chowmushih/
    end

    def draw_highlighted_line(line, row, start_col, width)
      display_line = highlight_keywords(line)
      display_line = highlight_quotes(display_line)
      Terminal.write(row, start_col, Terminal::ANSI::WHITE + display_line[0, width] + Terminal::ANSI::RESET)
    end

    def highlight_keywords(line)
      keywords = /Chinese poets|philosophers|Taoyuen-ming|celebrated|fragrance|plum-blossoms|Linwosing|Chowmushih/
      line.gsub(keywords) { |match| Terminal::ANSI::CYAN + match + Terminal::ANSI::WHITE }
    end

    def highlight_quotes(line)
      line.gsub(/("[^"]+")|('[^']+')/) do |match|
        Terminal::ANSI::ITALIC + match + Terminal::ANSI::RESET + Terminal::ANSI::WHITE
      end
    end

    def draw_page_number(start_row, start_col, width, height, offset, actual_height, lines)
      return unless @config.show_page_numbers && lines.size.positive? && actual_height.positive?

      page_num = (offset / actual_height) + 1
      total_pages = [(lines.size.to_f / actual_height).ceil, 1].max
      page_text = "#{page_num}/#{total_pages}"
      page_row = start_row + height - 1

      return if page_row >= Terminal.size[0] - 2

      Terminal.write(page_row, [start_col + width - page_text.length, start_col].max,
                     Terminal::ANSI::DIM + Terminal::ANSI::GRAY + page_text + Terminal::ANSI::RESET)
    end

    def draw_help_screen(height, width)
      help_lines = build_help_lines
      start_row = [(height - help_lines.size) / 2, 1].max

      help_lines.each_with_index do |line, idx|
        row = start_row + idx
        break if row >= height - 2

        col = [(width - line.length) / 2, 1].max
        Terminal.write(row, col, Terminal::ANSI::WHITE + line + Terminal::ANSI::RESET)
      end
    end

    def build_help_lines
      [
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
    end

    def draw_toc_screen(height, width)
      draw_toc_header(width)
      draw_toc_list(height, width)
      draw_toc_footer(height)
    end

    def draw_toc_header(width)
      Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}📖 Table of Contents#{Terminal::ANSI::RESET}")
      Terminal.write(1, [width - 30, 40].max,
                     "#{Terminal::ANSI::DIM}[t/ESC] Back to Reading#{Terminal::ANSI::RESET}")
    end

    def draw_toc_list(height, width)
      list_start = 4
      list_height = height - 6
      chapters = @doc.chapters
      return if chapters.empty?

      visible_range = calculate_toc_visible_range(list_height, chapters.length)
      draw_toc_items(visible_range, chapters, list_start, width)
    end

    def calculate_toc_visible_range(list_height, chapter_count)
      visible_start = [@toc_selected - (list_height / 2), 0].max
      visible_end = [visible_start + list_height, chapter_count].min
      visible_start...visible_end
    end

    def draw_toc_items(range, chapters, list_start, width)
      range.each_with_index do |idx, row|
        chapter = chapters[idx]
        line = "#{idx + 1}. #{chapter[:title] || 'Untitled'}"

        if idx == @toc_selected
          Terminal.write(list_start + row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
          Terminal.write(list_start + row, 4,
                         Terminal::ANSI::BRIGHT_WHITE + line[0, width - 6] + Terminal::ANSI::RESET)
        else
          Terminal.write(list_start + row, 4, Terminal::ANSI::WHITE + line[0, width - 6] + Terminal::ANSI::RESET)
        end
      end
    end

    def draw_toc_footer(height)
      Terminal.write(height - 1, 2,
                     "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Jump • t/ESC Back#{Terminal::ANSI::RESET}")
    end

    def draw_bookmarks_screen(height, width)
      draw_bookmarks_header(width)

      if @bookmarks.empty?
        draw_empty_bookmarks(height, width)
      else
        draw_bookmarks_list(height, width)
      end

      draw_bookmarks_footer(height)
    end

    def draw_bookmarks_header(width)
      Terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}🔖 Bookmarks#{Terminal::ANSI::RESET}")
      Terminal.write(1, [width - 40, 40].max,
                     "#{Terminal::ANSI::DIM}[B/ESC] Back [d] Delete#{Terminal::ANSI::RESET}")
    end

    def draw_empty_bookmarks(height, width)
      Terminal.write(height / 2, (width - 20) / 2,
                     "#{Terminal::ANSI::DIM}No bookmarks yet.#{Terminal::ANSI::RESET}")
      Terminal.write((height / 2) + 1, (width - 30) / 2,
                     "#{Terminal::ANSI::DIM}Press 'b' while reading to add one.#{Terminal::ANSI::RESET}")
    end

    def draw_bookmarks_list(height, width)
      list_start = 4
      list_height = (height - 6) / 2
      visible_range = calculate_bookmark_visible_range(list_height)

      draw_bookmark_items(visible_range, list_start, width)
    end

    def calculate_bookmark_visible_range(list_height)
      visible_start = [@bookmark_selected - (list_height / 2), 0].max
      visible_end = [visible_start + list_height, @bookmarks.length].min
      visible_start...visible_end
    end

    def draw_bookmark_items(range, list_start, width)
      range.each_with_index do |idx, row_idx|
        bookmark = @bookmarks[idx]
        chapter_title = @doc.get_chapter(bookmark['chapter'])&.[](:title) || "Chapter #{bookmark['chapter'] + 1}"

        draw_bookmark_item(bookmark, chapter_title, idx, list_start + (row_idx * 2), width)
      end
    end

    def draw_bookmark_item(bookmark, chapter_title, idx, row, width)
      line1 = "Ch. #{bookmark['chapter'] + 1}: #{chapter_title}"
      line2 = "  > #{bookmark['text']}"

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

    def draw_bookmarks_footer(height)
      Terminal.write(height - 1, 2,
                     "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Jump • d Delete • B/ESC Back#{Terminal::ANSI::RESET}")
    end

    def adjust_for_line_spacing(height)
      case @config.line_spacing
      when :compact then height
      when :relaxed then [height / 2, 1].max
      else [(height * 0.8).to_i, 1].max
      end
    end

    def process_input(key)
      return unless key

      case @mode
      when :help then @mode = :read
      when :toc then handle_toc_input(key)
      when :bookmarks then handle_bookmarks_input(key)
      else handle_reading_input(key)
      end
    end

    def handle_reading_input(key)
      case key
      when 'q' then quit_to_menu
      when 'Q' then quit_application
      when '?' then @mode = :help
      when 't', 'T' then open_toc
      when 'b' then add_bookmark
      when 'B' then open_bookmarks
      when 'v', 'V' then toggle_view_mode
      when '+' then increase_line_spacing
      when '-' then decrease_line_spacing
      else handle_navigation_input(key)
      end
    end

    def quit_to_menu
      save_progress
      @running = false
    end

    def quit_application
      save_progress
      Terminal.cleanup
      exit 0
    end

    def open_toc
      @mode = :toc
      @toc_selected = @current_chapter
    end

    def open_bookmarks
      @mode = :bookmarks
      @bookmark_selected = 0
    end

    def toggle_view_mode
      @config.view_mode = @config.view_mode == :split ? :single : :split
      @config.save
      @last_width = 0
      @last_height = 0
      reset_pages
    end

    def increase_line_spacing
      modes = %i[compact normal relaxed]
      current = modes.index(@config.line_spacing) || 1
      return unless current < 2

      @config.line_spacing = modes[current + 1]
      @config.save
      @last_width = 0
    end

    def decrease_line_spacing
      modes = %i[compact normal relaxed]
      current = modes.index(@config.line_spacing) || 1
      return unless current.positive?

      @config.line_spacing = modes[current - 1]
      @config.save
      @last_width = 0
    end

    def handle_navigation_input(key)
      height, width = Terminal.size
      col_width, content_height = get_layout_metrics(width, height)
      content_height = adjust_for_line_spacing(content_height)

      chapter = @doc.get_chapter(@current_chapter)
      return unless chapter

      wrapped = wrap_lines(chapter[:lines] || [], col_width)
      max_page = [wrapped.size - content_height, 0].max

      navigate_by_key(key, content_height, max_page)
    end

    def navigate_by_key(key, content_height, max_page)
      case key
      when 'j', "\e[B", "\eOB" then scroll_down(max_page)
      when 'k', "\e[A", "\eOA" then scroll_up
      when 'l', ' ', "\e[C", "\eOC" then next_page(content_height, max_page)
      when 'h', "\e[D", "\eOD" then prev_page(content_height)
      when 'n', 'N' then next_chapter if @current_chapter < @doc.chapter_count - 1
      when 'p', 'P' then prev_chapter if @current_chapter.positive?
      when 'g' then reset_pages
      when 'G' then go_to_end(content_height, max_page)
      end
    end

    def scroll_down(max_page)
      if @config.view_mode == :split
        @left_page = [@left_page + 1, max_page].min
        @right_page = [@right_page + 1, max_page].min
      else
        @single_page = [@single_page + 1, max_page].min
      end
    end

    def scroll_up
      if @config.view_mode == :split
        @left_page = [@left_page - 1, 0].max
        @right_page = [@right_page - 1, 0].max
      else
        @single_page = [@single_page - 1, 0].max
      end
    end

    def next_page(content_height, max_page)
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
    end

    def prev_page(content_height)
      if @config.view_mode == :split
        if @left_page.positive?
          @right_page = @left_page
          @left_page = [@left_page - content_height, 0].max
        elsif @current_chapter.positive?
          prev_chapter(go_to_end: true)
        end
      elsif @single_page.positive?
        @single_page = [@single_page - content_height, 0].max
      elsif @current_chapter.positive?
        prev_chapter(go_to_end: true)
      end
    end

    def go_to_end(content_height, max_page)
      if @config.view_mode == :split
        @right_page = max_page
        @left_page = [max_page - content_height, 0].max
      else
        @single_page = max_page
      end
    end

    def handle_toc_input(key)
      if %w[t T].include?(key) || escape_key?(key)
        @mode = :read
      elsif navigation_key?(key)
        @toc_selected = handle_navigation_keys(key, @toc_selected, @doc.chapter_count - 1)
      elsif enter_key?(key)
        jump_to_chapter(@toc_selected)
      end
    end

    def jump_to_chapter(chapter_index)
      @current_chapter = chapter_index
      reset_pages
      save_progress
      @mode = :read
    end

    def handle_bookmarks_input(key)
      return handle_empty_bookmarks_input(key) if @bookmarks.empty?

      if ['B'].include?(key) || escape_key?(key)
        @mode = :read
      elsif navigation_key?(key)
        @bookmark_selected = handle_navigation_keys(key, @bookmark_selected, @bookmarks.length - 1)
      elsif enter_key?(key)
        jump_to_bookmark
      elsif %w[d D].include?(key)
        delete_selected_bookmark
      end
    end

    def handle_empty_bookmarks_input(key)
      @mode = :read if ['B'].include?(key) || escape_key?(key)
    end

    def jump_to_bookmark
      bookmark = @bookmarks[@bookmark_selected]
      return unless bookmark

      @current_chapter = bookmark['chapter']
      self.page_offsets = bookmark['line_offset']
      save_progress
      @mode = :read
    end

    def delete_selected_bookmark
      bookmark = @bookmarks[@bookmark_selected]
      return unless bookmark

      BookmarkManager.delete(@path, bookmark)
      load_bookmarks
      @bookmark_selected = [@bookmark_selected, @bookmarks.length - 1].min if @bookmarks.any?
      set_message('Bookmark deleted!')
    end

    def reset_pages
      self.page_offsets = 0
    end

    def next_chapter
      @current_chapter += 1
      reset_pages
      save_progress
    end

    def prev_chapter(go_to_end: false)
      @current_chapter -= 1

      if go_to_end
        position_at_chapter_end
      else
        reset_pages
      end
    end

    def position_at_chapter_end
      chapter = @doc.get_chapter(@current_chapter)
      return unless chapter && chapter[:lines]

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
  end
end
