# frozen_string_literal: true

module EbookReader
  # The command-line interface for the Ebook Reader application.
  class CLI
    def self.run
      debug = ARGV.include?('--debug') || ENV['DEBUG']

      Infrastructure::Logger.output = debug ? STDOUT : File.open(File::NULL, 'w')
      Infrastructure::Logger.level = debug ? :debug : :error

      MainMenu.new.run
    end
  end
end
