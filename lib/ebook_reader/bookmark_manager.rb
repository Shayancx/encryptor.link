# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'

module EbookReader
  # Bookmark manager
  class BookmarkManager
    CONFIG_DIR = File.expand_path('~/.config/reader')
    BOOKMARKS_FILE = File.join(CONFIG_DIR, 'bookmarks.json')

    def self.add(path, chapter, line_offset, text)
      bookmarks = load_all
      entry = build_entry(chapter, line_offset, text)
      bookmarks[path] = append_bookmark(bookmarks[path], entry)
      save_all(bookmarks)
    end

    def self.get(path)
      load_all[path] || []
    end

    def self.delete(path, bookmark_to_delete)
      bookmarks = load_all
      return unless bookmarks[path]

      bookmarks[path].reject! { |bookmark| bookmark['timestamp'] == bookmark_to_delete['timestamp'] }
      save_all(bookmarks)
    end

    def self.build_entry(chapter, line_offset, text)
      {
        'chapter' => chapter,
        'line_offset' => line_offset,
        'text' => text,
        'timestamp' => Time.now.iso8601
      }
    end

    private_class_method def self.append_bookmark(list, entry)
      list ||= []
      list << entry
      list.sort_by { |bm| [bm['chapter'], bm['line_offset']] }
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
