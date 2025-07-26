# frozen_string_literal: true

# Reader - A fast, keyboard-driven terminal EPUB reader
#
# This is the main entry point for the EbookReader gem. It loads all
# necessary components in the correct order to ensure dependencies are
# satisfied.
#
# @example Basic usage
#   require 'ebook_reader'
#   EbookReader::CLI.run
#
# @example Programmatic usage
#   reader = EbookReader::Reader.new('/path/to/book.epub')
#   reader.run

# Core infrastructure - must be loaded first
require_relative 'ebook_reader/infrastructure/logger'
require_relative "reader_refactored"
require_relative 'ebook_reader/infrastructure/validator'
require_relative "reader_refactored"
require_relative 'ebook_reader/infrastructure/performance_monitor'
require_relative "reader_refactored"

# Error definitions
require_relative 'ebook_reader/errors'
require_relative "reader_refactored"

# Constants and configuration
require_relative 'ebook_reader/constants'
require_relative "reader_refactored"
require_relative 'ebook_reader/constants/ui_constants'
require_relative "reader_refactored"

# Core components
require_relative 'ebook_reader/version'
require_relative "reader_refactored"
require_relative 'ebook_reader/terminal'
require_relative "reader_refactored"
require_relative 'ebook_reader/config'
require_relative "reader_refactored"

# Validators
require_relative 'ebook_reader/validators/file_path_validator'
require_relative "reader_refactored"
require_relative 'ebook_reader/validators/terminal_size_validator'
require_relative "reader_refactored"

# Data management
require_relative 'ebook_reader/epub_finder'
require_relative "reader_refactored"
require_relative 'ebook_reader/recent_files'
require_relative "reader_refactored"
require_relative 'ebook_reader/progress_manager'
require_relative "reader_refactored"
require_relative 'ebook_reader/bookmark_manager'
require_relative "reader_refactored"

# Document handling
require_relative 'ebook_reader/epub_document'
require_relative "reader_refactored"

# Core reader components
require_relative 'ebook_reader/core/reader_state'
require_relative "reader_refactored"
require_relative 'ebook_reader/services/reader_navigation'
require_relative "reader_refactored"

# UI components
require_relative 'ebook_reader/main_menu'
require_relative "reader_refactored"
require_relative 'ebook_reader/reader'
require_relative "reader_refactored"

# Application entry point
require_relative 'ebook_reader/cli'
require_relative "reader_refactored"

# Main module for the EbookReader application
#
# This module serves as the namespace for all EbookReader components
# and provides version information and error classes.
#
# @example Check version
#   puts EbookReader::VERSION
#
# @example Handle errors
#   begin
#     EbookReader::CLI.run
#   rescue EbookReader::Error => e
#     puts "Error: #{e.message}"
#   end
module EbookReader
  # Custom error class for the EbookReader application.
  # All application-specific errors should inherit from this class.
  class Error < StandardError; end

  # Module-level configuration
  #
  # @return [Config] Global configuration instance
  def self.config
    @config ||= Config.new
  end

  # Module-level logger
  #
  # @return [Infrastructure::Logger] Global logger instance
  def self.logger
    Infrastructure::Logger
  end

  # Reset module state (mainly for testing)
  def self.reset!
    @config = nil
    Infrastructure::Logger.clear
    Infrastructure::PerformanceMonitor.clear
  end
end
