# frozen_string_literal: true

module EbookReader
  module UI
    module Screens
      class MenuScreen
        attr_accessor :selected

        def initialize(renderer, selected)
          @renderer = renderer
          @selected = selected
        end

        def draw(height, width)
          menu_start = @renderer.render_logo(height, width)
          menu_items = build_menu_items
          render_menu_items(menu_items, menu_start, height, width)
          @renderer.render_footer(height, width,
                                  'Navigate with ↑↓ or jk • Select with Enter')
        end

        private

        def build_menu_items
          [
            { key: 'f', icon: '', text: 'Find Book', desc: 'Browse all EPUBs' },
            { key: 'r', icon: '󰁯', text: 'Recent', desc: 'Recently opened books' },
            { key: 'o', icon: '󰷏', text: 'Open File', desc: 'Enter path manually' },
            { key: 's', icon: '', text: 'Settings', desc: 'Configure reader' },
            { key: 'q', icon: '󰿅', text: 'Quit', desc: 'Exit application' },
          ]
        end

        def render_menu_items(items, start_row, height, width)
          items.each_with_index do |item, i|
            row = start_row + (i * 2)
            next if row >= height - 2

            pointer_col = [(width / 2) - 20, 2].max
            text_col = [(width / 2) - 18, 4].max

            @renderer.render_menu_item(row, pointer_col, text_col, item,
                                       i == @selected)
          end
        end
      end
    end
  end
end
