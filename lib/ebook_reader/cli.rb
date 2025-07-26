# frozen_string_literal: true

module EbookReader
  # The command-line interface for the Ebook Reader application.
  class CLI
    def self.run
      Infrastructure::Logger.output = File.open(File::NULL, 'w')
      Infrastructure::Logger.level = :error

      MainMenu.new.run
    end
  end
end
