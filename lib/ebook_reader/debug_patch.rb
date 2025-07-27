# frozen_string_literal: true

module EbookReader
  class MainMenu
    private

    alias original_open_book open_book if private_method_defined?(:open_book)

    def open_book(path)
      log_open_attempt(path)
      return handle_missing_file unless File.exist?(path)

      begin
        launch_reader(path)
      rescue ArgumentError => e
        handle_argument_error(e, path)
      rescue StandardError => e
        handle_standard_error(e, path)
      ensure
        Terminal.setup
      end
    end

    def log_open_attempt(path)
      return unless ENV['DEBUG']

      puts "\n[DEBUG] Attempting to open: #{path}"
      puts "[DEBUG] File exists: #{File.exist?(path)}"
      size = begin
        File.size(path)
      rescue StandardError
        'N/A'
      end
      puts "[DEBUG] File size: #{size}"
    end

    def handle_missing_file
      @scanner.scan_message = 'File not found'
      @scanner.scan_status = :error
    end

    def launch_reader(path)
      Terminal.cleanup
      RecentFiles.add(path)
      puts "[DEBUG] Creating EPUBDocument..." if ENV['DEBUG']
      reader = Reader.new(path, @config)
      puts "[DEBUG] Starting reader.run..." if ENV['DEBUG']
      reader.run
    end

    def handle_argument_error(error, path)
      log_exception('ArgumentError', error) if ENV['DEBUG']
      Infrastructure::Logger.error('ArgumentError opening book', error: error.message, path:)
      @scanner.scan_message = "Argument error: #{error.message[0, 40]}"
      @scanner.scan_status = :error
    end

    def handle_standard_error(error, path)
      log_exception(error.class.to_s, error) if ENV['DEBUG']
      Infrastructure::Logger.error('Failed to open book', error: error.message, path:)
      @scanner.scan_message = "Failed: #{error.class.name}: #{error.message[0, 40]}"
      @scanner.scan_status = :error
    end

    def log_exception(title, error)
      puts "\n[DEBUG] #{title}: #{error.message}"
      puts "[DEBUG] Backtrace:\n#{error.backtrace.first(5).join("\n")}"
    end
  end
end
