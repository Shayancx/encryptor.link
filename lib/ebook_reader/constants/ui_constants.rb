# frozen_string_literal: true

module EbookReader
  module Constants
    # UI Layout Constants
    module UIConstants
      # Terminal defaults
      DEFAULT_HEIGHT = 24
      DEFAULT_WIDTH = 80
      MIN_HEIGHT = 10
      MIN_WIDTH = 40

      # Layout spacing
      HEADER_HEIGHT = 2
      FOOTER_HEIGHT = 2
      CONTENT_PADDING = 2
      SCROLL_INDICATOR_WIDTH = 2

      # Menu layout
      MENU_ITEM_SPACING = 2
      MENU_POINTER_OFFSET = 2
      MENU_TEXT_OFFSET = 4

      # Reader layout
      SPLIT_VIEW_DIVIDER_WIDTH = 5
      SINGLE_VIEW_MAX_WIDTH = 120
      MIN_COLUMN_WIDTH = 20

      # Time formatting
      MINUTE = 60
      HOUR = 3600
      DAY = 86_400
      WEEK = 604_800

      # Visual indicators
      POINTER_SYMBOL = '▸'
      DIVIDER_SYMBOL = '│'
      SCROLL_SYMBOL = '▐'

      # Key repeat delay (ms)
      KEY_REPEAT_DELAY = 20
    end
  end
end
