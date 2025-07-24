# frozen_string_literal: true

require 'fileutils'
require 'json'

module EbookReader
  # Configuration manager
  class Config
    attr_accessor :view_mode, :theme, :show_page_numbers, :line_spacing, :highlight_quotes

    CONFIG_DIR = File.expand_path('~/.config/simple-novel-reader')
    CONFIG_FILE = File.join(CONFIG_DIR, 'config.json')

    def initialize
      @view_mode = :split # :split or :single
      @theme = :dark
      @show_page_numbers = true
      @line_spacing = :normal # :compact, :normal, :relaxed
      @highlight_quotes = true
      load_config
    end

    def save
      begin
        FileUtils.mkdir_p(CONFIG_DIR)
      rescue StandardError
        nil
      end
      begin
        File.write(CONFIG_FILE, JSON.pretty_generate(to_h))
      rescue StandardError
        nil
      end
    end

    def to_h
      {
        view_mode: @view_mode,
        theme: @theme,
        show_page_numbers: @show_page_numbers,
        line_spacing: @line_spacing,
        highlight_quotes: @highlight_quotes
      }
    end

    private

    def load_config
      return unless File.exist?(CONFIG_FILE)

      data = JSON.parse(File.read(CONFIG_FILE), symbolize_names: true)
      @view_mode = data[:view_mode]&.to_sym || @view_mode
      @theme = data[:theme]&.to_sym || @theme
      @show_page_numbers = data.fetch(:show_page_numbers, @show_page_numbers)
      @line_spacing = data[:line_spacing]&.to_sym || @line_spacing
      @highlight_quotes = data.fetch(:highlight_quotes, @highlight_quotes)
    rescue StandardError
      # Use defaults on error
    end
  end
end
