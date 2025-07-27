# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'

module EbookReader
  # Manages a list of recently opened files.
  class RecentFiles
    CONFIG_DIR = File.expand_path('~/.config/reader')
    RECENT_FILE = File.join(CONFIG_DIR, 'recent.json')
    MAX_RECENT_FILES = 10

    class << self
      # Adds a file path to the top of the recent files list.
      #
      # @param path [String] The path to the file to add.
      def add(path)
        recent_files = load.reject { |file| file['path'] == path }

        new_entry = {
          'path' => path,
          'name' => File.basename(path, '.epub').tr('_-', ' '),
          'accessed' => Time.now.iso8601,
        }

        save([new_entry, *recent_files].first(MAX_RECENT_FILES))
      end

      # Loads the list of recent files from disk.
      #
      # @return [Array<Hash>] An array of recent file entries.
      def load
        return [] unless File.exist?(RECENT_FILE)

        JSON.parse(File.read(RECENT_FILE))
      rescue JSON::ParserError, Errno::ENOENT
        []
      end

      private

      # Saves the list of recent files to disk.
      #
      # @param recent [Array<Hash>] The list of recent files to save.
      def save(recent)
        FileUtils.mkdir_p(CONFIG_DIR)
        File.write(RECENT_FILE, JSON.pretty_generate(recent))
      rescue Errno::EACCES, Errno::ENOENT
        # Silently ignore file system errors, as this is not a critical feature.
      end
    end
  end
end
