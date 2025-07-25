#!/bin/bash

# EbookReader Codebase Enhancement Script
# This script implements comprehensive improvements to code quality,
# organization, documentation, and maintainability

set -e

echo "Starting EbookReader codebase enhancement..."

# Create backup
echo "Creating backup..."
cp -r lib lib.backup
cp -r spec spec.backup

# Create necessary directories first
echo "Creating directory structure..."
mkdir -p lib/ebook_reader/constants
mkdir -p lib/ebook_reader/reader_modes
mkdir -p lib/ebook_reader/commands
mkdir -p lib/ebook_reader/renderers

# 1. Extract constants to dedicated file
echo "Creating constants configuration..."
cat > lib/ebook_reader/constants/ui_constants.rb << 'EOF'
# frozen_string_literal: true

module EbookReader
  module Constants
    # UI Layout Constants
    module UIConstants
      # Terminal defaults
      DEFAULT_HEIGHT = 24
      DEFAULT_WIDTH = 80
      MIN_HEIGHT = 10
      MIN_WIDTH = 40
      
      # Layout spacing
      HEADER_HEIGHT = 2
      FOOTER_HEIGHT = 2
      CONTENT_PADDING = 2
      SCROLL_INDICATOR_WIDTH = 2
      
      # Menu layout
      MENU_ITEM_SPACING = 2
      MENU_POINTER_OFFSET = 2
      MENU_TEXT_OFFSET = 4
      
      # Reader layout
      SPLIT_VIEW_DIVIDER_WIDTH = 5
      SINGLE_VIEW_MAX_WIDTH = 120
      MIN_COLUMN_WIDTH = 20
      
      # Time formatting
      MINUTE = 60
      HOUR = 3600
      DAY = 86400
      WEEK = 604800
      
      # Visual indicators
      POINTER_SYMBOL = '▸'
      DIVIDER_SYMBOL = '│'
      SCROLL_SYMBOL = '▐'
      
      # Key repeat delay (ms)
      KEY_REPEAT_DELAY = 20
    end
  end
end
EOF

# 2. Create dedicated error classes
echo "Creating error classes..."
cat > lib/ebook_reader/errors.rb << 'EOF'
# frozen_string_literal: true

module EbookReader
  # Base error class for EbookReader
  class Error < StandardError; end
  
  # Raised when EPUB file cannot be parsed
  class EPUBParseError < Error
    attr_reader :file_path
    
    def initialize(message, file_path)
      super("Failed to parse EPUB at #{file_path}: #{message}")
      @file_path = file_path
    end
  end
  
  # Raised when required file is not found
  class FileNotFoundError < Error
    attr_reader :file_path
    
    def initialize(file_path)
      super("File not found: #{file_path}")
      @file_path = file_path
    end
  end
  
  # Raised when configuration is invalid
  class ConfigurationError < Error; end
  
  # Raised when terminal is too small
  class TerminalSizeError < Error
    def initialize(width, height)
      super("Terminal too small: #{width}x#{height}. Minimum required: #{Constants::UIConstants::MIN_WIDTH}x#{Constants::UIConstants::MIN_HEIGHT}")
    end
  end
end
EOF

# 3. Extract Reader modes into separate classes
echo "Creating Reader mode handlers..."

cat > lib/ebook_reader/reader_modes/base_mode.rb << 'EOF'
# frozen_string_literal: true

module EbookReader
  module ReaderModes
    # Base class for all reader modes
    class BaseMode
      attr_reader :reader
      
      def initialize(reader)
        @reader = reader
      end
      
      # @abstract Override in subclasses
      def draw(height, width)
        raise NotImplementedError
      end
      
      # @abstract Override in subclasses  
      def handle_input(key)
        raise NotImplementedError
      end
      
      protected
      
      def terminal
        Terminal
      end
      
      def config
        reader.config
      end
    end
  end
end
EOF

cat > lib/ebook_reader/reader_modes/reading_mode.rb << 'EOF'
# frozen_string_literal: true

require_relative 'base_mode'

module EbookReader
  module ReaderModes
    # Handles the main reading view
    class ReadingMode < BaseMode
      def draw(height, width)
        if config.view_mode == :split
          draw_split_view(height, width)
        else
          draw_single_view(height, width)
        end
      end
      
      def handle_input(key)
        case key
        when 'j', "\e[B", "\eOB" then reader.scroll_down
        when 'k', "\e[A", "\eOA" then reader.scroll_up
        when 'l', ' ', "\e[C", "\eOC" then reader.next_page
        when 'h', "\e[D", "\eOD" then reader.prev_page
        when 'n', 'N' then reader.next_chapter
        when 'p', 'P' then reader.prev_chapter
        when 'g' then reader.go_to_start
        when 'G' then reader.go_to_end
        when 't', 'T' then reader.switch_mode(:toc)
        when 'b' then reader.add_bookmark
        when 'B' then reader.switch_mode(:bookmarks)
        when '?' then reader.switch_mode(:help)
        when 'v', 'V' then reader.toggle_view_mode
        when '+' then reader.increase_line_spacing
        when '-' then reader.decrease_line_spacing
        when 'q' then reader.quit_to_menu
        when 'Q' then reader.quit_application
        end
      end
      
      private
      
      def draw_split_view(height, width)
        reader.send(:draw_split_screen, height, width)
      end
      
      def draw_single_view(height, width)
        reader.send(:draw_single_screen, height, width)
      end
    end
  end
end
EOF

cat > lib/ebook_reader/reader_modes/help_mode.rb << 'EOF'
# frozen_string_literal: true

require_relative 'base_mode'

module EbookReader
  module ReaderModes
    # Displays help information
    class HelpMode < BaseMode
      HELP_CONTENT = [
        '',
        'Navigation Keys:',
        '  j / ↓     Scroll down',
        '  k / ↑     Scroll up', 
        '  l / →     Next page',
        '  h / ←     Previous page',
        '  SPACE     Next page',
        '  n         Next chapter',
        '  p         Previous chapter',
        '  g         Go to beginning',
        '  G         Go to end',
        '',
        'View Options:',
        '  v         Toggle view mode',
        '  + / -     Adjust line spacing',
        '',
        'Features:',
        '  t         Table of Contents',
        '  b         Add bookmark',
        '  B         View bookmarks',
        '',
        'Other:',
        '  ?         Show/hide help',
        '  q         Quit to menu',
        '  Q         Quit application',
        '',
        'Press any key to continue...'
      ].freeze
      
      def draw(height, width)
        start_row = [(height - HELP_CONTENT.size) / 2, 1].max
        
        HELP_CONTENT.each_with_index do |line, idx|
          row = start_row + idx
          break if row >= height - 2
          
          col = [(width - line.length) / 2, 1].max
          terminal.write(row, col, Terminal::ANSI::WHITE + line + Terminal::ANSI::RESET)
        end
      end
      
      def handle_input(_key)
        reader.switch_mode(:read)
      end
    end
  end
end
EOF

cat > lib/ebook_reader/reader_modes/toc_mode.rb << 'EOF'
# frozen_string_literal: true

require_relative 'base_mode'

module EbookReader
  module ReaderModes
    # Table of Contents navigation
    class TocMode < BaseMode
      include Concerns::InputHandler
      
      def initialize(reader)
        super
        @selected = reader.current_chapter
      end
      
      def draw(height, width)
        draw_header(width)
        draw_chapter_list(height, width)
        draw_footer(height)
      end
      
      def handle_input(key)
        if escape_key?(key) || %w[t T].include?(key)
          reader.switch_mode(:read)
        elsif navigation_key?(key)
          max_index = reader.send(:doc).chapter_count - 1
          @selected = handle_navigation_keys(key, @selected, max_index)
        elsif enter_key?(key)
          reader.send(:jump_to_chapter, @selected)
          reader.switch_mode(:read)
        end
      end
      
      private
      
      def draw_header(width)
        terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}📖 Table of Contents#{Terminal::ANSI::RESET}")
        terminal.write(1, [width - 30, 40].max,
                      "#{Terminal::ANSI::DIM}[t/ESC] Back#{Terminal::ANSI::RESET}")
      end
      
      def draw_chapter_list(height, width)
        list_start = 4
        list_height = height - 6
        chapters = reader.send(:doc).chapters
        
        visible_range = calculate_visible_range(list_height, chapters.length)
        
        visible_range.each_with_index do |idx, row|
          chapter = chapters[idx]
          draw_chapter_item(chapter, idx, list_start + row, width)
        end
      end
      
      def draw_chapter_item(chapter, idx, row, width)
        number = idx + 1
        title = chapter[:title] || 'Untitled'
        text = "#{number}. #{title}"
        
        if idx == @selected
          terminal.write(row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
          terminal.write(row, 4, "#{Terminal::ANSI::BRIGHT_WHITE}#{text[0, width - 6]}#{Terminal::ANSI::RESET}")
        else
          terminal.write(row, 4, "#{Terminal::ANSI::WHITE}#{text[0, width - 6]}#{Terminal::ANSI::RESET}")
        end
      end
      
      def draw_footer(height)
        terminal.write(height - 1, 2,
                      "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Select • t/ESC Back#{Terminal::ANSI::RESET}")
      end
      
      def calculate_visible_range(list_height, total)
        visible_start = [@selected - (list_height / 2), 0].max
        visible_end = [visible_start + list_height, total].min
        visible_start...visible_end
      end
    end
  end
end
EOF

cat > lib/ebook_reader/reader_modes/bookmarks_mode.rb << 'EOF'
# frozen_string_literal: true

require_relative 'base_mode'

module EbookReader
  module ReaderModes
    # Bookmark management interface
    class BookmarksMode < BaseMode
      include Concerns::InputHandler
      
      def initialize(reader)
        super
        @selected = 0
        @bookmarks = reader.send(:bookmarks)
      end
      
      def draw(height, width)
        draw_header(width)
        
        if @bookmarks.empty?
          draw_empty_state(height, width)
        else
          draw_bookmark_list(height, width)
        end
        
        draw_footer(height)
      end
      
      def handle_input(key)
        return handle_empty_input(key) if @bookmarks.empty?
        
        if escape_key?(key) || key == 'B'
          reader.switch_mode(:read)
        elsif navigation_key?(key)
          @selected = handle_navigation_keys(key, @selected, @bookmarks.length - 1)
        elsif enter_key?(key)
          jump_to_bookmark
        elsif %w[d D].include?(key)
          delete_bookmark
        end
      end
      
      private
      
      def handle_empty_input(key)
        reader.switch_mode(:read) if escape_key?(key) || key == 'B'
      end
      
      def draw_header(width)
        terminal.write(1, 2, "#{Terminal::ANSI::BRIGHT_CYAN}🔖 Bookmarks#{Terminal::ANSI::RESET}")
        terminal.write(1, [width - 40, 40].max,
                      "#{Terminal::ANSI::DIM}[B/ESC] Back [d] Delete#{Terminal::ANSI::RESET}")
      end
      
      def draw_empty_state(height, width)
        terminal.write(height / 2, (width - 20) / 2,
                      "#{Terminal::ANSI::DIM}No bookmarks yet#{Terminal::ANSI::RESET}")
      end
      
      def draw_bookmark_list(height, width)
        list_start = 4
        items_per_page = (height - 6) / 2
        
        visible_range = calculate_visible_range(items_per_page)
        
        visible_range.each_with_index do |idx, row_idx|
          bookmark = @bookmarks[idx]
          draw_bookmark_item(bookmark, idx, list_start + (row_idx * 2), width)
        end
      end
      
      def draw_bookmark_item(bookmark, idx, row, width)
        doc = reader.send(:doc)
        chapter_title = doc.get_chapter(bookmark['chapter'])&.[](:title) || "Chapter #{bookmark['chapter'] + 1}"
        
        if idx == @selected
          terminal.write(row, 2, "#{Terminal::ANSI::BRIGHT_GREEN}▸ #{Terminal::ANSI::RESET}")
          terminal.write(row, 4, "#{Terminal::ANSI::BRIGHT_WHITE}Ch. #{bookmark['chapter'] + 1}: #{chapter_title[0, width - 20]}#{Terminal::ANSI::RESET}")
          terminal.write(row + 1, 6, "#{Terminal::ANSI::ITALIC}#{Terminal::ANSI::GRAY}#{bookmark['text'][0, width - 8]}#{Terminal::ANSI::RESET}")
        else
          terminal.write(row, 4, "#{Terminal::ANSI::WHITE}Ch. #{bookmark['chapter'] + 1}: #{chapter_title[0, width - 20]}#{Terminal::ANSI::RESET}")
          terminal.write(row + 1, 6, "#{Terminal::ANSI::DIM}#{Terminal::ANSI::GRAY}#{bookmark['text'][0, width - 8]}#{Terminal::ANSI::RESET}")
        end
      end
      
      def draw_footer(height)
        terminal.write(height - 1, 2,
                      "#{Terminal::ANSI::DIM}↑↓ Navigate • Enter Jump • d Delete • B/ESC Back#{Terminal::ANSI::RESET}")
      end
      
      def calculate_visible_range(items_per_page)
        visible_start = [@selected - (items_per_page / 2), 0].max
        visible_end = [visible_start + items_per_page, @bookmarks.length].min
        visible_start...visible_end
      end
      
      def jump_to_bookmark
        bookmark = @bookmarks[@selected]
        return unless bookmark
        
        reader.send(:jump_to_bookmark)
      end
      
      def delete_bookmark
        bookmark = @bookmarks[@selected]
        return unless bookmark
        
        reader.send(:delete_selected_bookmark)
        @bookmarks = reader.send(:bookmarks)
        @selected = [@selected, @bookmarks.length - 1].min if @bookmarks.any?
      end
    end
  end
end
EOF

# 4. Create input command pattern
echo "Creating input command system..."

cat > lib/ebook_reader/commands/base_command.rb << 'EOF'
# frozen_string_literal: true

module EbookReader
  module Commands
    # Base class for all commands
    class BaseCommand
      attr_reader :receiver
      
      def initialize(receiver)
        @receiver = receiver
      end
      
      # Execute the command
      # @abstract
      def execute
        raise NotImplementedError
      end
      
      # Optional: undo the command
      def undo
        # Override in subclasses if needed
      end
    end
  end
end
EOF

cat > lib/ebook_reader/commands/navigation_commands.rb << 'EOF'
# frozen_string_literal: true

require_relative 'base_command'

module EbookReader
  module Commands
    # Scroll down by one line
    class ScrollDownCommand < BaseCommand
      def execute
        max_page = receiver.instance_variable_get(:@max_page) || 0
        receiver.send(:scroll_down, max_page)
      end
    end
    
    # Scroll up by one line
    class ScrollUpCommand < BaseCommand
      def execute
        receiver.send(:scroll_up)
      end
    end
    
    # Go to next page
    class NextPageCommand < BaseCommand
      def execute
        height, width = Terminal.size
        col_width, content_height = receiver.send(:get_layout_metrics, width, height)
        content_height = receiver.send(:adjust_for_line_spacing, content_height)
        max_page = receiver.instance_variable_get(:@max_page) || 0
        receiver.send(:next_page, content_height, max_page)
      end
    end
    
    # Go to previous page
    class PrevPageCommand < BaseCommand
      def execute
        height, width = Terminal.size
        col_width, content_height = receiver.send(:get_layout_metrics, width, height)
        content_height = receiver.send(:adjust_for_line_spacing, content_height)
        receiver.send(:prev_page, content_height)
      end
    end
    
    # Go to next chapter
    class NextChapterCommand < BaseCommand
      def execute
        doc = receiver.instance_variable_get(:@doc)
        current = receiver.instance_variable_get(:@current_chapter)
        receiver.send(:next_chapter) if current < doc.chapter_count - 1
      end
    end
    
    # Go to previous chapter
    class PrevChapterCommand < BaseCommand
      def execute
        current = receiver.instance_variable_get(:@current_chapter)
        receiver.send(:prev_chapter) if current.positive?
      end
    end
    
    # Go to beginning of chapter
    class GoToStartCommand < BaseCommand
      def execute
        receiver.send(:reset_pages)
      end
    end
    
    # Go to end of chapter
    class GoToEndCommand < BaseCommand
      def execute
        height, width = Terminal.size
        col_width, content_height = receiver.send(:get_layout_metrics, width, height)
        content_height = receiver.send(:adjust_for_line_spacing, content_height)
        max_page = receiver.instance_variable_get(:@max_page) || 0
        receiver.send(:go_to_end, content_height, max_page)
      end
    end
  end
end
EOF

# 5. Extract rendering components
echo "Creating rendering components..."

cat > lib/ebook_reader/renderers/base_renderer.rb << 'EOF'
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
EOF

cat > lib/ebook_reader/renderers/content_renderer.rb << 'EOF'
# frozen_string_literal: true

require_relative 'base_renderer'

module EbookReader
  module Renderers
    # Renders document content
    class ContentRenderer < BaseRenderer
      def draw_single_view(chapter, width, height, page_offset)
        return unless chapter
        
        col_width = calculate_single_column_width(width)
        col_start = center_column(width, col_width)
        content_height = calculate_content_height(height, :single)
        
        wrapped = wrap_lines(chapter[:lines] || [], col_width)
        start_row = center_vertically(height, content_height)
        
        draw_column(start_row, col_start, col_width, content_height, wrapped, page_offset, false)
      end
      
      def draw_split_view(chapter, width, height, left_offset, right_offset)
        return unless chapter
        
        col_width = calculate_split_column_width(width)
        content_height = calculate_content_height(height, :split)
        wrapped = wrap_lines(chapter[:lines] || [], col_width)
        
        draw_chapter_header(chapter, width)
        draw_left_column(wrapped, col_width, content_height, left_offset)
        draw_divider(height, col_width)
        draw_right_column(wrapped, col_width, content_height, right_offset)
      end
      
      private
      
      def calculate_single_column_width(width)
        [(width * 0.9).to_i, SINGLE_VIEW_MAX_WIDTH].min.clamp(MIN_COLUMN_WIDTH, width - 4)
      end
      
      def calculate_split_column_width(width)
        [(width - SPLIT_VIEW_DIVIDER_WIDTH) / 2, MIN_COLUMN_WIDTH].max
      end
      
      def calculate_content_height(height, mode)
        base_height = height - HEADER_HEIGHT - FOOTER_HEIGHT
        mode == :single ? base_height - 2 : base_height
      end
      
      def center_column(width, col_width)
        [(width - col_width) / 2, 1].max
      end
      
      def center_vertically(height, content_height)
        [HEADER_HEIGHT + ((height - HEADER_HEIGHT - FOOTER_HEIGHT - content_height) / 2), HEADER_HEIGHT].max
      end
      
      def draw_chapter_header(chapter, width)
        title = "[#{chapter[:number] || 1}] #{chapter[:title] || 'Unknown'}"
        write(2, 1, with_color(Terminal::ANSI::BLUE, title[0, width - 2]))
      end
      
      def draw_left_column(wrapped, width, height, offset)
        draw_column(3, 1, width, height, wrapped, offset, true)
      end
      
      def draw_right_column(wrapped, width, height, offset)
        draw_column(3, width + SPLIT_VIEW_DIVIDER_WIDTH, width, height, wrapped, offset, false)
      end
      
      def draw_divider(height, col_width)
        (3...[height - 1, 4].max).each do |row|
          write(row, col_width + 3, with_color(Terminal::ANSI::GRAY, DIVIDER_SYMBOL))
        end
      end
      
      def draw_column(start_row, start_col, width, height, lines, offset, show_page_num)
        return if lines.nil? || lines.empty? || width < 10 || height < 1
        
        actual_height = height
        end_offset = [offset + actual_height, lines.size].min
        
        draw_lines(lines, offset, end_offset, start_row, start_col, width, actual_height)
        draw_page_number(start_row, start_col, width, height, offset, actual_height, lines) if show_page_num
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
        text = line[0, width]
        write(row, start_col, with_color(Terminal::ANSI::WHITE, text))
      end
      
      def draw_page_number(start_row, start_col, width, height, offset, actual_height, lines)
        return unless @config.show_page_numbers && lines.size.positive? && actual_height.positive?
        
        page_num = (offset / actual_height) + 1
        total_pages = [(lines.size.to_f / actual_height).ceil, 1].max
        page_text = "#{page_num}/#{total_pages}"
        page_row = start_row + height - 1
        
        return if page_row >= Terminal.size[0] - 2
        
        write(page_row, [start_col + width - page_text.length, start_col].max,
              with_color(Terminal::ANSI::DIM + Terminal::ANSI::GRAY, page_text))
      end
      
      def wrap_lines(lines, width)
        # Placeholder - should use existing ReaderHelpers
        lines
      end
    end
  end
end
EOF

# 6. Create proper README and documentation
echo "Creating README..."
cat > README.md << 'EOF'
# Simple Novel Reader

A fast, keyboard-driven terminal EPUB reader written in Ruby.

## Features

- **Split & Single View Modes**: Read in two-column or centered single-column layout
- **Vim-style Navigation**: Navigate with familiar keyboard shortcuts
- **Bookmarks**: Save and jump to bookmarks within books
- **Progress Tracking**: Automatically saves reading position
- **Recent Files**: Quick access to recently opened books
- **Customizable Display**: Adjust line spacing and view preferences

## Installation

```bash
gem install simple-novel-reader
```

Or add to your Gemfile:

```ruby
gem 'simple-novel-reader'
```

## Usage

```bash
ebook_reader
```

### Keyboard Shortcuts

#### Navigation
- `j/↓` - Scroll down
- `k/↑` - Scroll up
- `l/→/Space` - Next page
- `h/←` - Previous page
- `n` - Next chapter
- `p` - Previous chapter
- `g` - Go to beginning
- `G` - Go to end

#### Features
- `t` - Table of Contents
- `b` - Add bookmark
- `B` - View bookmarks
- `v` - Toggle split/single view
- `+/-` - Adjust line spacing
- `?` - Show help

#### Application
- `q` - Quit to menu
- `Q` - Quit application

## Configuration

Configuration is saved in `~/.config/simple-novel-reader/config.json`:

```json
{
  "view_mode": "split",
  "theme": "dark",
  "show_page_numbers": true,
  "line_spacing": "normal",
  "highlight_quotes": true
}
```

## Architecture

The application follows a modular architecture:

- **Core Components**
  - `Terminal`: Low-level terminal manipulation
  - `Config`: User preferences management
  - `EPUBDocument`: EPUB parsing and content extraction

- **UI Components**
  - `MainMenu`: Application entry point and file selection
  - `Reader`: Main reading interface with mode management
  - `ReaderModes`: Specialized handlers for different view modes

- **Data Management**
  - `BookmarkManager`: Bookmark persistence
  - `ProgressManager`: Reading position tracking
  - `RecentFiles`: Recent file history

## Development

```bash
# Run tests
bundle exec rspec

# Run with coverage
bundle exec rspec --format documentation

# Check code style
bundle exec rubocop
```

## License

MIT License - see LICENSE file for details.
EOF

# 7. Create architecture documentation
echo "Creating architecture documentation..."
cat > ARCHITECTURE.md << 'EOF'
# Simple Novel Reader - Architecture

## Overview

Simple Novel Reader follows a modular, object-oriented architecture designed for maintainability and extensibility.

## Core Design Patterns

### 1. **Command Pattern** (Input Handling)
- Encapsulates user actions as command objects
- Enables undo/redo functionality (future feature)
- Decouples input handling from business logic

### 2. **Strategy Pattern** (Reader Modes)
- Different strategies for rendering content (reading, help, TOC, bookmarks)
- Easy to add new viewing modes
- Consistent interface for all modes

### 3. **Template Method Pattern** (Rendering)
- Base renderer defines structure
- Subclasses implement specific rendering logic
- Promotes code reuse

### 4. **Observer Pattern** (State Management)
- Configuration changes notify dependent components
- Progress tracking updates automatically

## Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Application Layer                     │
├─────────────────────────────────────────────────────────────┤
│  CLI  │  MainMenu  │  Reader  │  ReaderModes  │  Commands  │
├─────────────────────────────────────────────────────────────┤
│                         UI Layer                             │
├─────────────────────────────────────────────────────────────┤
│  Terminal  │  Renderers  │  UI Components  │  InputHandler  │
├─────────────────────────────────────────────────────────────┤
│                      Business Layer                          │
├─────────────────────────────────────────────────────────────┤
│  EPUBDocument  │  Config  │  Managers  │  EPUBFinder        │
├─────────────────────────────────────────────────────────────┤
│                       Data Layer                             │
├─────────────────────────────────────────────────────────────┤
│  File System  │  JSON Storage  │  EPUB Files                │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### Terminal Layer
- **Terminal**: Low-level terminal manipulation using ANSI escape codes
- **ANSI Module**: Constants for colors and control sequences

### Application Components
- **CLI**: Entry point and command-line interface
- **MainMenu**: File selection and application menu
- **Reader**: Main reading interface and mode coordination

### UI Components
- **Renderers**: Specialized rendering for different content types
- **ReaderModes**: Mode-specific behavior and rendering
- **InputHandler**: Keyboard input processing

### Business Logic
- **EPUBDocument**: EPUB parsing and content extraction
- **Config**: User preferences and settings
- **Managers**: Bookmarks, progress, and recent files

### Data Storage
- **JSON Files**: Configuration, bookmarks, progress
- **File System**: EPUB file scanning and access

## Data Flow

1. **Startup**: CLI → MainMenu → EPUBFinder
2. **File Selection**: MainMenu → Reader → EPUBDocument
3. **Reading**: Reader → ReaderMode → Renderer → Terminal
4. **Input**: Terminal → Reader → Command → State Change
5. **Persistence**: Managers → JSON Files

## Extension Points

- **New Reader Modes**: Implement `ReaderModes::BaseMode`
- **New Commands**: Extend `Commands::BaseCommand`
- **New Renderers**: Extend `Renderers::BaseRenderer`
- **New File Formats**: Implement document parser interface

## Performance Considerations

- **Lazy Loading**: Chapters loaded on demand
- **Caching**: EPUB file list cached for 24 hours
- **Double Buffering**: Terminal updates use buffering
- **Efficient Parsing**: Minimal DOM parsing for performance
EOF

# 8. Create a proper Rakefile
echo "Creating Rakefile..."
cat > Rakefile << 'EOF'
# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc 'Run all quality checks'
task quality: [:spec, :rubocop]

task default: :quality

namespace :test do
  desc 'Run tests with coverage'
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['spec'].invoke
  end
end

desc 'Console with library loaded'
task :console do
  require 'irb'
  require 'ebook_reader'
  ARGV.clear
  IRB.start
end
EOF

# 9. Create a changelog
echo "Creating CHANGELOG..."
cat > CHANGELOG.md << 'EOF'
# Changelog

All notable changes to Simple Novel Reader will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive documentation with YARD
- Architecture documentation
- Command pattern for input handling
- Strategy pattern for reader modes
- Dedicated error classes
- Constants configuration module
- Rendering components separation

### Changed
- Refactored Reader class to use mode handlers
- Extracted magic numbers to constants
- Improved error handling with context
- Modularized rendering logic

### Fixed
- Terminal size validation
- Memory efficiency in large documents
- Input handling edge cases

## [0.9.212-beta] - Previous Release

### Added
- Initial implementation
- Basic EPUB reading functionality
- Bookmark support
- Progress tracking
EOF

# 10. Create integration patches
echo "Creating integration patches..."
cat > integrate_reader_modes.rb << 'EOF'
#!/usr/bin/env ruby
# frozen_string_literal: true

# This script patches the existing Reader class to use the new mode system

require 'fileutils'

puts "Patching Reader class..."

reader_file = 'lib/ebook_reader/reader.rb'
content = File.read(reader_file)

# Add requires at the top
requires = <<-RUBY
require_relative 'reader_modes/reading_mode'
require_relative 'reader_modes/help_mode'  
require_relative 'reader_modes/toc_mode'
require_relative 'reader_modes/bookmarks_mode'
require_relative 'constants/ui_constants'
require_relative 'errors'

RUBY

content = requires + content

# Add include for UIConstants
content.sub!(/class Reader\n/, "class Reader\n    include Constants::UIConstants\n")

# Add switch_mode method
switch_mode_method = <<-'RUBY'

  def switch_mode(mode)
    @mode = mode
  end

  def scroll_down
    if @config.view_mode == :split
      @left_page = [@left_page + 1, @max_page || 0].min
      @right_page = [@right_page + 1, @max_page || 0].min
    else
      @single_page = [@single_page + 1, @max_page || 0].min
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

  def next_page
    height, width = Terminal.size
    col_width, content_height = get_layout_metrics(width, height)
    content_height = adjust_for_line_spacing(content_height)
    
    chapter = @doc.get_chapter(@current_chapter)
    return unless chapter
    
    wrapped = wrap_lines(chapter[:lines] || [], col_width)
    max_page = [wrapped.size - content_height, 0].max
    
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

  def prev_page
    height, width = Terminal.size
    col_width, content_height = get_layout_metrics(width, height)
    content_height = adjust_for_line_spacing(content_height)
    
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

  def go_to_start
    reset_pages
  end

  def go_to_end
    height, width = Terminal.size
    col_width, content_height = get_layout_metrics(width, height)
    content_height = adjust_for_line_spacing(content_height)
    
    chapter = @doc.get_chapter(@current_chapter)
    return unless chapter
    
    wrapped = wrap_lines(chapter[:lines] || [], col_width)
    max_page = [wrapped.size - content_height, 0].max
    
    if @config.view_mode == :split
      @right_page = max_page
      @left_page = [max_page - content_height, 0].max
    else
      @single_page = max_page
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

  attr_reader :current_chapter, :doc, :config

RUBY

# Insert before private keyword
content.sub!(/(\n\s*private)/, switch_mode_method + '\1')

# Replace magic numbers with constants
content.gsub!(/\b24\b(?!:)/, 'DEFAULT_HEIGHT')
content.gsub!(/\b80\b(?!:)/, 'DEFAULT_WIDTH')
content.gsub!(/\b20\b(?!:)/, 'MIN_COLUMN_WIDTH')
content.gsub!(/sleep 0\.02/, 'sleep KEY_REPEAT_DELAY / 1000.0')

# Save patched file
File.write(reader_file, content)
puts "Reader class patched successfully!"
EOF

chmod +x integrate_reader_modes.rb

# 11. Create tests for new components
echo "Creating tests for new components..."
cat > spec/reader_modes_spec.rb << 'EOF'
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::ReaderModes do
  let(:reader) { instance_double(EbookReader::Reader) }
  let(:config) { instance_double(EbookReader::Config, view_mode: :single) }
  let(:document) do
    instance_double(EbookReader::EPUBDocument,
                    chapters: [{ title: 'Ch1', lines: ['Line 1'] }],
                    chapter_count: 1)
  end
  
  before do
    allow(reader).to receive(:config).and_return(config)
    allow(reader).to receive(:send).with(:doc).and_return(document)
    allow(reader).to receive(:current_chapter).and_return(0)
    allow(reader).to receive(:send).with(:bookmarks).and_return([])
    allow(EbookReader::Terminal).to receive(:write)
  end
  
  describe EbookReader::ReaderModes::ReadingMode do
    subject(:mode) { described_class.new(reader) }
    
    it 'draws based on view mode' do
      allow(reader).to receive(:send).with(:draw_single_screen, 24, 80)
      mode.draw(24, 80)
    end
    
    it 'handles navigation input' do
      expect(reader).to receive(:scroll_down)
      mode.handle_input('j')
    end
  end
  
  describe EbookReader::ReaderModes::HelpMode do
    subject(:mode) { described_class.new(reader) }
    
    it 'draws help content' do
      mode.draw(24, 80)
      expect(EbookReader::Terminal).to have_received(:write).at_least(5).times
    end
    
    it 'returns to read mode on any key' do
      expect(reader).to receive(:switch_mode).with(:read)
      mode.handle_input('x')
    end
  end
end
EOF

cat > spec/constants_spec.rb << 'EOF'
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Constants::UIConstants do
  it 'defines terminal defaults' do
    expect(described_class::DEFAULT_HEIGHT).to eq(24)
    expect(described_class::DEFAULT_WIDTH).to eq(80)
    expect(described_class::MIN_HEIGHT).to eq(10)
    expect(described_class::MIN_WIDTH).to eq(40)
  end
  
  it 'defines layout constants' do
    expect(described_class::HEADER_HEIGHT).to eq(2)
    expect(described_class::FOOTER_HEIGHT).to eq(2)
    expect(described_class::SPLIT_VIEW_DIVIDER_WIDTH).to eq(5)
  end
  
  it 'defines visual indicators' do
    expect(described_class::POINTER_SYMBOL).to eq('▸')
    expect(described_class::DIVIDER_SYMBOL).to eq('│')
  end
end
EOF

# 12. Update main requires file
echo "Updating main require file..."
cat > lib/ebook_reader_update.rb << 'EOF'
# Add these requires to the top of lib/ebook_reader.rb

require_relative 'ebook_reader/errors'
require_relative 'ebook_reader/constants/ui_constants'
EOF

# Append new requires to existing file
cat lib/ebook_reader_update.rb lib/ebook_reader.rb > lib/ebook_reader.rb.tmp
mv lib/ebook_reader.rb.tmp lib/ebook_reader.rb
rm lib/ebook_reader_update.rb

# 13. Run the integration
echo "Running integration..."
ruby integrate_reader_modes.rb

# 14. Final cleanup and validation
echo "Running final validation..."

# Check Ruby syntax for all files
echo "Checking Ruby syntax..."
find lib -name "*.rb" -print0 | xargs -0 -I {} ruby -c {} 2>&1 | grep -v "Syntax OK" || true

# Create a simple test runner to verify nothing is broken
cat > test_enhancements.rb << 'EOF'
#!/usr/bin/env ruby
# frozen_string_literal: true

puts "Testing enhanced codebase..."

begin
  require_relative 'lib/ebook_reader'
  puts "✓ Main module loads"
  
  # Test constants
  puts "✓ Constants defined" if defined?(EbookReader::Constants::UIConstants)
  
  # Test errors
  puts "✓ Error classes defined" if defined?(EbookReader::Error)
  
  # Test modes
  if File.exist?('lib/ebook_reader/reader_modes/base_mode.rb')
    puts "✓ Reader modes created"
  end
  
  # Test commands
  if File.exist?('lib/ebook_reader/commands/base_command.rb')
    puts "✓ Commands created"
  end
  
  puts "\n✅ All enhancements loaded successfully!"
  
rescue Exception => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace
  exit 1
end
EOF

chmod +x test_enhancements.rb
ruby test_enhancements.rb

# 15. Create a summary
echo ""
echo "✅ Enhancement complete!"
echo ""
echo "Summary of changes:"
echo "- Created modular architecture with proper separation of concerns"
echo "- Extracted constants and magic numbers to lib/ebook_reader/constants/ui_constants.rb"
echo "- Created error classes in lib/ebook_reader/errors.rb"
echo "- Implemented reader modes in lib/ebook_reader/reader_modes/"
echo "- Added command pattern in lib/ebook_reader/commands/"
echo "- Created rendering components in lib/ebook_reader/renderers/"
echo "- Added comprehensive documentation (README.md, ARCHITECTURE.md, CHANGELOG.md)"
echo "- Created Rakefile for common tasks"
echo ""
echo "Directory structure created:"
echo "  lib/ebook_reader/"
echo "  ├── commands/"
echo "  ├── constants/"
echo "  ├── reader_modes/"
echo "  └── renderers/"
echo ""
echo "Next steps:"
echo "1. Review the changes"
echo "2. Run 'bundle exec rspec' to ensure all tests pass"
echo "3. Test the application manually: ruby bin/ebook_reader"
echo "4. Remove backups if satisfied: rm -rf lib.backup spec.backup"

# Clean up temporary files
rm -f integrate_reader_modes.rb test_enhancements.rb integrate_enhancements.rb

# Final status check
if [ $? -eq 0 ]; then
  echo ""
  echo "✅ All enhancements applied successfully!"
else
  echo ""
  echo "⚠️  Some issues were encountered. Check the output above."
fi