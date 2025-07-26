module EbookReader
  class MainMenu
    private
    
    alias_method :original_open_book, :open_book if private_method_defined?(:open_book)
    
    def open_book(path)
      puts "\n[DEBUG] Attempting to open: #{path}" if ENV['DEBUG']
      puts "[DEBUG] File exists: #{File.exist?(path)}" if ENV['DEBUG']
      puts "[DEBUG] File size: #{File.size(path) rescue 'N/A'}" if ENV['DEBUG']
      
      unless File.exist?(path)
        @scanner.scan_message = 'File not found'
        @scanner.scan_status = :error
        return
      end

      begin
        Terminal.cleanup
        RecentFiles.add(path)
        
        puts "[DEBUG] Creating EPUBDocument..." if ENV['DEBUG']
        reader = Reader.new(path, @config)
        
        puts "[DEBUG] Starting reader.run..." if ENV['DEBUG']
        reader.run
      rescue ArgumentError => e
        puts "\n[DEBUG] ArgumentError: #{e.message}" if ENV['DEBUG']
        puts "[DEBUG] Backtrace:\n#{e.backtrace.join("\n")}" if ENV['DEBUG']
        Infrastructure::Logger.error('ArgumentError opening book', error: e.message, path: path)
        @scanner.scan_message = "Argument error: #{e.message[0, 40]}"
        @scanner.scan_status = :error
      rescue StandardError => e
        puts "\n[DEBUG] Error: #{e.class}: #{e.message}" if ENV['DEBUG']
        puts "[DEBUG] Backtrace:\n#{e.backtrace.first(5).join("\n")}" if ENV['DEBUG']
        Infrastructure::Logger.error('Failed to open book', error: e.message, path: path)
        @scanner.scan_message = "Failed: #{e.class.name}: #{e.message[0, 40]}"
        @scanner.scan_status = :error
      ensure
        Terminal.setup
      end
    end
  end
end
