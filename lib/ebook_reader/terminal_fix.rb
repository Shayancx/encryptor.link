# frozen_string_literal: true

module EbookReader
  class Terminal
    class << self
      alias read_key get_key
      remove_method :get_key
    end
  end
end
