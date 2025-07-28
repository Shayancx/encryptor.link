module EbookReader
  module Services
    class PageManager
      attr_reader :pages_data

      def initialize(doc, config)
        @doc = doc
        @config = config
        @pages_data = []
      end

      def build_page_map(terminal_width, terminal_height)
        return unless @config.page_numbering_mode == :dynamic

        @pages_data = []
        col_width, content_height = calculate_layout_metrics(terminal_width, terminal_height)
        lines_per_page = adjust_for_line_spacing(content_height)
        return if lines_per_page <= 0

        @doc.chapters.each_with_index do |chapter, chapter_idx|
          wrapped_lines = wrap_chapter_lines(chapter, col_width)
          page_count = (wrapped_lines.size.to_f / lines_per_page).ceil
          page_count = 1 if page_count < 1

          page_count.times do |page_idx|
            start_line = page_idx * lines_per_page
            end_line = [start_line + lines_per_page - 1, wrapped_lines.size - 1].min

            @pages_data << {
              chapter_index: chapter_idx,
              page_in_chapter: page_idx,
              total_pages_in_chapter: page_count,
              start_line: start_line,
              end_line: end_line,
              lines: wrapped_lines[start_line..end_line] || []
            }
          end
        end

        @pages_data
      end

      def get_page(page_index)
        return nil if @pages_data.empty?
        return @pages_data.first if page_index < 0
        return @pages_data.last if page_index >= @pages_data.size

        @pages_data[page_index]
      end

      def find_page_index(chapter_index, line_offset)
        @pages_data.find_index do |page|
          page[:chapter_index] == chapter_index &&
            line_offset >= page[:start_line] &&
            line_offset <= page[:end_line]
        end || 0
      end

      def total_pages
        @pages_data.size
      end

      private

      def calculate_layout_metrics(width, height)
        col_width = if @config.view_mode == :split
                       [(width - 3) / 2, 20].max
                     else
                       (width * 0.9).to_i.clamp(30, 120)
                     end
        content_height = [height - 4, 1].max
        [col_width, content_height]
      end

      def adjust_for_line_spacing(height)
        case @config.line_spacing
        when :relaxed
          [height / 2, 1].max
        when :compact
          height
        else
          [(height * 0.8).to_i, 1].max
        end
      end

      def wrap_chapter_lines(chapter, width)
        return [] unless chapter.lines

        wrapped = []
        chapter.lines.each do |line|
          next if line.nil?

          if line.strip.empty?
            wrapped << ''
          else
            wrap_line(line, width, wrapped)
          end
        end
        wrapped
      end

      def wrap_line(line, width, wrapped)
        words = line.split(/\s+/)
        current = ''

        words.each do |word|
          next if word.nil?

          if current.empty?
            current = word
          elsif current.length + 1 + word.length <= width
            current += " #{word}"
          else
            wrapped << current
            current = word
          end
        end
        wrapped << current unless current.empty?
      end
    end
  end
end
