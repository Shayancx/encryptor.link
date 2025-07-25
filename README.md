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
