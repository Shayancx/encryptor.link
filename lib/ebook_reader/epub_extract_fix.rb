# frozen_string_literal: true

module EbookReader
  class EPUBDocument
    private
    
    # Override extract_epub to handle different rubyzip versions
    alias_method :original_extract_epub, :extract_epub if private_method_defined?(:extract_epub)
    
    def extract_epub(tmpdir)
      Zip::File.open(@path) do |zip|
        zip.each do |entry|
          dest = File.join(tmpdir, entry.name)
          FileUtils.mkdir_p(File.dirname(dest))
          
          # Skip if already exists
          next if File.exist?(dest)
          
          # Extract the entry
          begin
            entry.extract(dest)
          rescue ArgumentError => e
            # If we get an argument error, try without the second argument
            if e.message.include?("wrong number of arguments")
              # For older rubyzip versions that don't accept overwrite parameter
              File.open(dest, 'wb') do |f|
                entry.get_input_stream do |input|
                  f.write(input.read)
                end
              end
            else
              raise
            end
          rescue StandardError => e
            # Last resort - manual extraction
            File.open(dest, 'wb') do |f|
              f.write(zip.read(entry))
            end
          end
        end
      end
    end
  end
end
