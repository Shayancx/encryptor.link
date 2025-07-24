# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'

module EbookReader
  # Bookmark manager
  class BookmarkManager
    CONFIG_DIR = File.expand_path('~/.config/simple-novel-reader')
    BOOKMARKS_FILE = File.join(CONFIG_DIR, 'bookmarks.json')

    def self.add(path, chapter, line_offset, text)
      bookmarks = load_all
      bookmarks[path] ||= []
      bookmarks[path] << {
        'chapter' => chapter,
        'line_offset' => line_offset,
        'text' => text,
        'timestamp' => Time.now.iso8601
      }
      bookmarks[path].sort_by! { |b| [b['chapter'], b['line_offset']] }
      save_all(bookmarks)
    end

    def self.get(path)
      load_all[path] || []
    end

    def self.delete(path, bookmark_to_delete)
      bookmarks = load_all
      return unless bookmarks[path]

      bookmarks[path].reject! { |b| b['timestamp'] == bookmark_to_delete['timestamp'] }
      save_all(bookmarks)
    end

    def self.load_all
      return {} unless File.exist?(BOOKMARKS_FILE)

      JSON.parse(File.read(BOOKMARKS_FILE))
    rescue StandardError
      {}
    end

    def self.save_all(bookmarks)
      File.write(BOOKMARKS_FILE, JSON.pretty_generate(bookmarks))
    rescue StandardError
      nil
    end
  end
end
