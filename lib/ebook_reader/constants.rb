# frozen_string_literal: true

module EbookReader
  # Central location for all application constants.
  # This module contains configuration values, limits, and
  # magic numbers used throughout the application.
  module Constants
    # Version of the configuration file format
    CONFIG_VERSION = 1

    # Application metadata
    APP_NAME = 'Reader'
    APP_AUTHOR = 'Your Name'
    APP_HOMEPAGE = 'https://github.com/yourusername/reader'

    # File system constants
    CONFIG_DIR = File.expand_path('~/.config/reader')
    CACHE_DIR = File.join(CONFIG_DIR, 'cache')
    LOG_DIR = File.join(CONFIG_DIR, 'logs')

    # File names
    CONFIG_FILE = 'config.json'
    BOOKMARKS_FILE = 'bookmarks.json'
    PROGRESS_FILE = 'progress.json'
    RECENT_FILE = 'recent.json'
    CACHE_FILE = 'epub_cache.json'

    # Scanning limits
    SCAN_TIMEOUT = 20         # Maximum time for system scan in seconds
    MAX_DEPTH = 3            # Maximum directory depth for scanning
    MAX_FILES = 500          # Maximum number of EPUB files to index
    CACHE_DURATION = 86_400  # Cache validity in seconds (24 hours)

    # Performance limits
    MAX_LINE_LENGTH = 120    # Maximum line length before wrapping
    MAX_CHAPTER_SIZE = 1_000_000  # Maximum chapter size in bytes
    RENDER_BUFFER_SIZE = 100      # Number of lines to buffer for rendering

    # Reader settings
    DEFAULT_LINE_SPACING = :normal
    LINE_SPACING_VALUES = %i[compact normal relaxed].freeze
    VIEW_MODES = %i[split single].freeze
    READER_MODES = %i[read help toc bookmarks].freeze

    # Recent files
    MAX_RECENT_FILES = 10

    # Skip directories for scanning
    SKIP_DIRS = %w[
      node_modules vendor cache tmp temp .git .svn
      __pycache__ build dist bin obj debug release
      .idea .vscode .atom .sublime library frameworks
      applications system windows programdata appdata
      .Trash .npm .gem .bundle .cargo .rustup .cache
      .local .config backup backups old archive
    ].freeze

    # File patterns
    EPUB_PATTERN = '*.epub'
    BACKUP_PATTERN = '*~'
    TEMP_PATTERN = '.*.tmp'

    # Time formatting
    MINUTE = 60
    HOUR = 3600
    DAY = 86_400
    WEEK = 604_800

    # Key repeat delay in milliseconds
    KEY_REPEAT_DELAY = 20

    # Debug settings
    DEBUG_MODE = ENV['DEBUG'] || ARGV.include?('--debug')

    # Logging levels
    LOG_LEVELS = %i[debug info warn error fatal].freeze
    DEFAULT_LOG_LEVEL = DEBUG_MODE ? :debug : :info

    # Performance thresholds
    SLOW_OPERATION_THRESHOLD = 1.0  # seconds
    MEMORY_WARNING_THRESHOLD = 100_000_000  # bytes (100MB)
  end
end
