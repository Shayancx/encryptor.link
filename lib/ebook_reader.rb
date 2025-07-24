# frozen_string_literal: true

require_relative 'ebook_reader/version'
require_relative 'ebook_reader/terminal'
require_relative 'ebook_reader/config'
require_relative 'ebook_reader/epub_finder'
require_relative 'ebook_reader/recent_files'
require_relative 'ebook_reader/progress_manager'
require_relative 'ebook_reader/bookmark_manager'
require_relative 'ebook_reader/main_menu'
require_relative 'ebook_reader/epub_document'
require_relative 'ebook_reader/reader'
require_relative 'ebook_reader/cli'

module EbookReader
  # Custom error class for the EbookReader application.
  class Error < StandardError; end
  # Your code goes here...
end
