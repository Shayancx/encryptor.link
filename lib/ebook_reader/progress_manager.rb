# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'

module EbookReader
  # Progress manager
  class ProgressManager
    CONFIG_DIR = File.expand_path('~/.config/reader')
    PROGRESS_FILE = File.join(CONFIG_DIR, 'progress.json')

    class << self
      # Persist the current reading progress for a given path.
      #
      # @param path [String] the epub file path
      # @param chapter [Integer] the chapter index
      # @param line_offset [Integer] the line offset within the chapter
      def save(path, chapter, line_offset)
        progress = load_all
        update_progress(progress, path, chapter: chapter, line_offset: line_offset)
        write_progress(progress)
      end

      def load(path)
        load_all[path]
      end

      def load_all
        return {} unless File.exist?(PROGRESS_FILE)

        JSON.parse(File.read(PROGRESS_FILE))
      rescue StandardError
        {}
      end

      private

      # Update the provided progress hash with new values for a path.
      #
      # @param progress [Hash] the progress hash loaded from disk
      # @param path [String] the epub file path
      # @param info [Hash] containing :chapter and :line_offset keys
      def update_progress(progress, path, info)
        progress[path] = {
          'chapter' => info[:chapter],
          'line_offset' => info[:line_offset],
          'timestamp' => Time.now.iso8601,
        }
      end

      def write_progress(progress)
        File.write(PROGRESS_FILE, JSON.pretty_generate(progress))
      rescue StandardError
        nil
      end
    end
  end
end
