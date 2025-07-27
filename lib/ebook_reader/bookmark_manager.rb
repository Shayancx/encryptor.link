# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'
require_relative 'models/bookmark'

module EbookReader
  # Bookmark manager
  class BookmarkManager
    CONFIG_DIR = File.expand_path('~/.config/reader')
    BOOKMARKS_FILE = File.join(CONFIG_DIR, 'bookmarks.json')

    def self.add(path, chapter, line_offset, text)
      bookmarks = load_all
      entry = build_entry(chapter, line_offset, text)
      list = (bookmarks[path] || []).map { |h| Models::Bookmark.from_h(h) }
      list = append_bookmark(list, entry)
      bookmarks[path] = list.map(&:to_h)
      save_all(bookmarks)
    end

    def self.get(path)
      (load_all[path] || []).map { |h| Models::Bookmark.from_h(h) }
    end

    def self.delete(path, bookmark_to_delete)
      bookmarks = load_all
      return unless bookmarks[path]

      bookmarks[path].reject! { |bookmark| bookmark['timestamp'] == bookmark_to_delete.created_at.iso8601 }
      save_all(bookmarks)
    end

    def self.build_entry(chapter, line_offset, text)
      Models::Bookmark.new(
        chapter_index: chapter,
        line_offset: line_offset,
        text_snippet: text,
        created_at: Time.now
      )
    end

    private_class_method def self.append_bookmark(list, entry)
      list ||= []
      list << entry
      list.sort_by { |bm| [bm.chapter_index, bm.line_offset] }
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
