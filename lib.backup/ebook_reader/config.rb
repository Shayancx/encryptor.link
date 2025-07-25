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
      set_defaults
      load_config
    end

    def save
      ensure_config_dir
      write_config_file
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

    def set_defaults
      @view_mode = :split
      @theme = :dark
      @show_page_numbers = true
      @line_spacing = :normal
      @highlight_quotes = true
    end

    def ensure_config_dir
      FileUtils.mkdir_p(CONFIG_DIR)
    rescue StandardError
      nil
    end

    def write_config_file
      File.write(CONFIG_FILE, JSON.pretty_generate(to_h))
    rescue StandardError
      nil
    end

    def load_config
      return unless File.exist?(CONFIG_FILE)

      data = parse_config_file
      apply_config_data(data) if data
    rescue StandardError
      # Use defaults on error
    end

    def parse_config_file
      JSON.parse(File.read(CONFIG_FILE), symbolize_names: true)
    rescue StandardError
      nil
    end

    def apply_config_data(data)
      @view_mode = data[:view_mode]&.to_sym || @view_mode
      @theme = data[:theme]&.to_sym || @theme
      @show_page_numbers = data.fetch(:show_page_numbers, @show_page_numbers)
      @line_spacing = data[:line_spacing]&.to_sym || @line_spacing
      @highlight_quotes = data.fetch(:highlight_quotes, @highlight_quotes)
    end
  end
end
