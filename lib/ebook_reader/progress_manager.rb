# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'

module EbookReader
  # Progress manager
  class ProgressManager
    CONFIG_DIR = File.expand_path('~/.config/simple-novel-reader')
    PROGRESS_FILE = File.join(CONFIG_DIR, 'progress.json')

    def self.save(path, chapter, line_offset)
      progress = load_all
      progress[path] = {
        'chapter' => chapter,
        'line_offset' => line_offset,
        'timestamp' => Time.now.iso8601
      }
      begin
        File.write(PROGRESS_FILE, JSON.pretty_generate(progress))
      rescue StandardError
        nil
      end
    end

    def self.load(path)
      load_all[path]
    end

    def self.load_all
      return {} unless File.exist?(PROGRESS_FILE)

      JSON.parse(File.read(PROGRESS_FILE))
    rescue StandardError
      {}
    end
  end
end
