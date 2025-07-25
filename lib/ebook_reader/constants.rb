# frozen_string_literal: true

module EbookReader
  # Constants used throughout the application
  module Constants
    # ANSI escape codes
    ESCAPE_CHAR = "\e"
    ESCAPE_CODE = "\x1B"

    # File paths
    CONFIG_DIR = File.expand_path('~/.config/simple-novel-reader')

    # Scan limits
    SCAN_TIMEOUT = 20
    MAX_DEPTH = 3
    MAX_FILES = 500

    # UI Constants
    MAX_LINE_LENGTH = 120

    # Skip directories for scanning
    SKIP_DIRS = %w[
      node_modules vendor cache tmp temp .git .svn
      __pycache__ build dist bin obj debug release
      .idea .vscode .atom .sublime library frameworks
      applications system windows programdata appdata
      .Trash .npm .gem .bundle
    ].freeze
  end
end
