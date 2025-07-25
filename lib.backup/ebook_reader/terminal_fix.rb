# frozen_string_literal: true

module EbookReader
  # Provides a small compatibility layer for the Terminal class.
  # Earlier versions exposed a `get_key` method. This file keeps
  # backward compatibility by aliasing `read_key` to `get_key` and
  # removing the old method name.
  class Terminal
    class << self
      alias read_key get_key
      remove_method :get_key
    end
  end
end
