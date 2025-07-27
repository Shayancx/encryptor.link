# frozen_string_literal: true

module EbookReader
  module Services
    # Handles all key input for MainMenu so the menu class focuses
    # on rendering and high level actions.
    class MainMenuInputHandler
      include Concerns::InputHandler

      def initialize(menu)
        @menu = menu
      end

      def handle_input(key)
        return unless key

        case @menu.instance_variable_get(:@mode)
        when :menu then handle_menu_input(key)
        when :browse then handle_browse_input(key)
        when :recent then handle_recent_input(key)
        when :settings then handle_settings_input(key)
        when :open_file then handle_open_file_input(key)
        end
      end

      def handle_menu_input(key)
        case key
        when 'q', 'Q' then @menu.send(:cleanup_and_exit, 0, '')
        when 'f', 'F' then @menu.send(:switch_to_browse)
        when 'r', 'R' then @menu.send(:switch_to_mode, :recent)
        when 'o', 'O' then @menu.send(:open_file_dialog)
        when 's', 'S' then @menu.send(:switch_to_mode, :settings)
        when 'j', "\e[B", "\eOB"
          selected = (@menu.instance_variable_get(:@selected) + 1) % 5
          @menu.instance_variable_set(:@selected, selected)
        when 'k', "\e[A", "\eOA"
          selected = (@menu.instance_variable_get(:@selected) - 1 + 5) % 5
          @menu.instance_variable_set(:@selected, selected)
        when "\r", "\n" then @menu.send(:handle_menu_selection)
        end
      end

      def handle_browse_input(key)
        if escape_key?(key)
          @menu.send(:switch_to_mode, :menu)
        elsif %w[r R].include?(key)
          @menu.send(:refresh_scan)
        elsif navigation_key?(key)
          @menu.send(:navigate_browse, key)
        elsif enter_key?(key)
          @menu.send(:open_selected_book)
        elsif key == '/'
          @menu.instance_variable_set(:@search_query, '')
          @menu.instance_variable_set(:@search_cursor, 0)
        elsif %W(\e[D \eOD).include?(key)
          @menu.send(:move_search_cursor, -1)
        elsif %W(\e[C \eOC).include?(key)
          @menu.send(:move_search_cursor, 1)
        elsif key == "\e[3~"
          @menu.send(:handle_delete)
        elsif backspace_key?(key)
          handle_backspace
        elsif searchable_key?(key)
          add_to_search(key)
        end
      end

      def handle_recent_input(key)
        recent = @menu.send(:load_recent_books)

        if escape_key?(key)
          @menu.send(:switch_to_mode, :menu)
        elsif navigation_key?(key) && recent.any?
          selected = handle_navigation_keys(key,
                                            @menu.instance_variable_get(:@browse_selected),
                                            recent.length - 1)
          @menu.instance_variable_set(:@browse_selected, selected)
        elsif enter_key?(key)
          book = recent[@menu.instance_variable_get(:@browse_selected)]
          if book && book['path'] && File.exist?(book['path'])
            @menu.send(:open_book, book['path'])
          else
            scanner = @menu.instance_variable_get(:@scanner)
            scanner.scan_message = 'File not found'
            scanner.scan_status = :error
          end
        end
      end

      def handle_settings_input(key)
        if escape_key?(key)
          @menu.send(:switch_to_mode, :menu)
          @menu.instance_variable_get(:@config).save
        else
          handle_setting_change(key)
        end
      end

      def handle_setting_change(key)
        case key
        when '1' then @menu.send(:toggle_view_mode)
        when '2' then @menu.send(:toggle_page_numbers)
        when '3' then @menu.send(:cycle_line_spacing)
        when '4' then @menu.send(:toggle_highlight_quotes)
        when '5' then @menu.send(:clear_cache)
        when '6' then @menu.send(:toggle_page_numbering_mode)
        end
      end

      def searchable_key?(key)
        return false unless key

        begin
          key = key.to_s.force_encoding('UTF-8')
          key.valid_encoding? && key =~ /[a-zA-Z0-9 .-]/
        rescue StandardError
          false
        end
      end

      def handle_backspace
        query = @menu.instance_variable_get(:@search_query).dup
        cursor = @menu.instance_variable_get(:@search_cursor)
        return if cursor <= 0

        query.slice!(cursor - 1)
        @menu.instance_variable_set(:@search_query, query)
        @menu.instance_variable_set(:@search_cursor, cursor - 1)
        @menu.send(:filter_books)
      end

      def add_to_search(key)
        query = @menu.instance_variable_get(:@search_query).dup
        cursor = @menu.instance_variable_get(:@search_cursor)
        query.insert(cursor, key)
        @menu.instance_variable_set(:@search_query, query)
        @menu.instance_variable_set(:@search_cursor, cursor + 1)
        @menu.send(:filter_books)
      end

      def handle_open_file_input(key)
        @menu.send(:handle_open_file_input, key)
      end
    end
  end
end
