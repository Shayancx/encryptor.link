# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'
require 'timeout'
require 'set'

module EbookReader
  # EPUB file finder with robust error handling
  class EPUBFinder
    SCAN_TIMEOUT = 20 # Maximum seconds for scanning
    MAX_DEPTH = 3 # Maximum directory depth
    MAX_FILES = 500 # Maximum EPUBs to find
    CONFIG_DIR = File.expand_path('~/.config/simple-novel-reader')
    CACHE_FILE = File.join(CONFIG_DIR, 'epub_cache.json')
    DEBUG_MODE = ARGV.include?('--debug') || ENV['DEBUG']

    def self.scan_system(force_refresh = false)
      # Try to load from cache first
      unless force_refresh
        cache = load_cache
        if cache && cache['files'].is_a?(Array) && !cache['files'].empty? && cache['timestamp'] && Time.now - Time.parse(cache['timestamp']) < 86_400
          # Check if cache is recent (less than 1 day old)
          return cache['files']
        end
      end

      # If cache is old or forced refresh, scan with timeout
      epubs = []
      begin
        Timeout.timeout(SCAN_TIMEOUT) do
          epubs = perform_scan
        end
      rescue Timeout::Error
        # If scan times out, return what we found so far
        save_cache(epubs) unless epubs.empty?
        return epubs
      rescue StandardError
        # On any other error, try to return cached data
        cache = load_cache
        return cache && cache['files'] ? cache['files'] : []
      end

      # Save results
      save_cache(epubs)
      epubs
    end

    def self.clear_cache
      File.delete(CACHE_FILE) if File.exist?(CACHE_FILE)
    rescue StandardError
      # Ignore errors
    end

    def self.perform_scan
      epubs = []
      visited_paths = Set.new

      # Start with most likely locations
      priority_dirs = [
        File.expand_path('~/Books'),
        File.expand_path('~/Documents/Books'),
        File.expand_path('~/Downloads'),
        File.expand_path('~/Desktop'),
        File.expand_path('~/Documents'),
        File.expand_path('~/Library/Mobile Documents') # iCloud on macOS
      ].select do |dir|
        Dir.exist?(dir)
       rescue StandardError
         false
      end

      # Then add other common locations
      other_dirs = [
        File.expand_path('~'),
        File.expand_path('~/Dropbox'),
        File.expand_path('~/Google Drive'),
        File.expand_path('~/OneDrive')
      ].select do |dir|
        Dir.exist?(dir)
      rescue StandardError
        false
      end

      all_dirs = (priority_dirs + other_dirs).uniq

      warn "Scanning directories: #{all_dirs.join(', ')}" if DEBUG_MODE

      all_dirs.each do |start_dir|
        break if epubs.length >= MAX_FILES

        warn "Scanning: #{start_dir}" if DEBUG_MODE
        scan_directory(start_dir, epubs, visited_paths, 0)
      end

      warn "Found #{epubs.length} EPUB files" if DEBUG_MODE
      epubs
    end

    def self.scan_directory(dir, epubs, visited_paths, depth)
      return if depth > MAX_DEPTH
      return if epubs.length >= MAX_FILES
      return if visited_paths.include?(dir)

      visited_paths.add(dir)

      begin
        entries = Dir.entries(dir)
        entries.each do |entry|
          next if entry.start_with?('.')

          path = File.join(dir, entry)

          # Skip if we've seen this path
          next if visited_paths.include?(path)

          begin
            if File.directory?(path)
              # Skip system and non-book directories
              base = File.basename(path).downcase
              skip_dirs = %w[
                node_modules vendor cache tmp temp .git .svn
                __pycache__ build dist bin obj debug release
                .idea .vscode .atom .sublime library frameworks
                applications system windows programdata appdata
                .Trash .npm .gem .bundle
              ]
              next if skip_dirs.include?(base)

              # Recursively scan subdirectory
              scan_directory(path, epubs, visited_paths, depth + 1)

            elsif path.downcase.end_with?('.epub')
              # Found an EPUB file
              if File.readable?(path) && File.size(path).positive?
                epubs << {
                  'path' => path,
                  'name' => File.basename(path, '.epub').gsub(/[_-]/, ' '),
                  'size' => File.size(path),
                  'modified' => File.mtime(path).iso8601,
                  'dir' => File.dirname(path)
                }
              end
            end
          rescue StandardError
            # Skip items we can't process
          end
        end
      rescue Errno::EACCES, Errno::ENOENT, Errno::EPERM
        # Skip directories we can't access
      rescue StandardError => e
        # Skip on any other error
        warn "Error scanning #{dir}: #{e.message}" if DEBUG_MODE
      end
    end

    def self.load_cache
      return nil unless File.exist?(CACHE_FILE)

      begin
        data = File.read(CACHE_FILE)
        json = JSON.parse(data)
        return nil unless json.is_a?(Hash)

        json
      rescue StandardError => e
        warn "Cache load error: #{e.message}" if DEBUG_MODE
        # If cache is corrupted, delete it
        begin
          File.delete(CACHE_FILE)
        rescue StandardError
          nil
        end
        nil
      end
    end

    def self.save_cache(files)
      FileUtils.mkdir_p(CONFIG_DIR)
      File.write(CACHE_FILE, JSON.pretty_generate({
                                                    'timestamp' => Time.now.iso8601,
                                                    'files' => files || [],
                                                    'version' => VERSION
                                                  }))
    rescue StandardError => e
      warn "Cache save error: #{e.message}" if DEBUG_MODE
    end
  end
end
