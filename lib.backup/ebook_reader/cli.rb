# frozen_string_literal: true

module EbookReader
  # The command-line interface for the Ebook Reader application.
  class CLI
    def self.run
      MainMenu.new.run
    end
  end
end
