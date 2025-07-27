# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Reader Modes Comprehensive" do
  let(:reader) { instance_double(EbookReader::Reader) }
  let(:config) { instance_double(EbookReader::Config) }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
                    chapters: [
                      { title: "Chapter 1", lines: ["Line 1"] },
                      { title: "Chapter 2", lines: ["Line 2"] }
                    ],
                    chapter_count: 2)
  end

  before do
    allow(reader).to receive(:config).and_return(config)
    allow(reader).to receive(:send).with(:doc).and_return(doc)
    allow(reader).to receive(:current_chapter).and_return(0)
    allow(EbookReader::Terminal).to receive(:write)
  end

  describe EbookReader::ReaderModes::ReadingMode do
    let(:mode) { described_class.new(reader) }

    describe 'input handling' do
      it 'handles all navigation keys' do
        # Test each navigation key
        %w[j k l h n p g G].each do |key|
          expect(reader).to receive(:scroll_down).at_least(:once) if key == 'j'
          expect(reader).to receive(:scroll_up).at_least(:once) if key == 'k'
          expect(reader).to receive(:next_page).at_least(:once) if key == 'l'
          expect(reader).to receive(:prev_page).at_least(:once) if key == 'h'
          expect(reader).to receive(:next_chapter).at_least(:once) if key == 'n'
          expect(reader).to receive(:prev_chapter).at_least(:once) if key == 'p'
          expect(reader).to receive(:go_to_start).at_least(:once) if key == 'g'
          expect(reader).to receive(:go_to_end).at_least(:once) if key == 'G'
          mode.handle_input(key)
        end
      end

      it 'handles mode switch keys' do
        expect(reader).to receive(:switch_mode).with(:toc)
        mode.handle_input('t')

        expect(reader).to receive(:add_bookmark)
        mode.handle_input('b')

        expect(reader).to receive(:switch_mode).with(:bookmarks)
        mode.handle_input('B')

        expect(reader).to receive(:switch_mode).with(:help)
        mode.handle_input('?')
      end

      it 'handles view adjustment keys' do
        expect(reader).to receive(:toggle_view_mode)
        mode.handle_input('v')

        expect(reader).to receive(:increase_line_spacing)
        mode.handle_input('+')

        expect(reader).to receive(:decrease_line_spacing)
        mode.handle_input('-')
      end

      it 'handles quit keys' do
        expect(reader).to receive(:quit_to_menu)
        mode.handle_input('q')

        expect(reader).to receive(:quit_application)
        mode.handle_input('Q')
      end
    end

    describe 'drawing' do
      it 'delegates to reader draw methods' do
        allow(config).to receive(:view_mode).and_return(:split)
        expect(reader).to receive(:send).with(:draw_split_screen, 24, 80)
        mode.draw(24, 80)

        allow(config).to receive(:view_mode).and_return(:single)
        expect(reader).to receive(:send).with(:draw_single_screen, 24, 80)
        mode.draw(24, 80)
      end
    end
  end

  describe EbookReader::ReaderModes::TocMode do
    let(:mode) { described_class.new(reader) }

    it 'initializes with current chapter selected' do
      allow(reader).to receive(:current_chapter).and_return(1)
      mode = described_class.new(reader)
      expect(mode.instance_variable_get(:@selected)).to eq(1)
    end

    it 'draws table of contents' do
      mode.draw(24, 80)
      expect(EbookReader::Terminal).to have_received(:write).at_least(5).times
    end

    it 'handles chapter selection' do
      expect(reader).to receive(:send).with(:jump_to_chapter, 0)
      expect(reader).to receive(:switch_mode).with(:read)
      mode.handle_input("\r")
    end

    it 'handles escape to reading mode' do
      expect(reader).to receive(:switch_mode).with(:read)
      mode.handle_input("\e")

      expect(reader).to receive(:switch_mode).with(:read)
      mode.handle_input("t")
    end
  end

  describe EbookReader::ReaderModes::BookmarksMode do
    let(:bookmarks) do
      [
        { 'chapter' => 0, 'line_offset' => 10, 'text' => 'Bookmark 1' },
        { 'chapter' => 1, 'line_offset' => 20, 'text' => 'Bookmark 2' }
      ]
    end
    let(:mode) { described_class.new(reader) }

    before do
      allow(reader).to receive(:send).with(:bookmarks).and_return(bookmarks)
    end

    it 'initializes with bookmarks' do
      expect(mode.instance_variable_get(:@bookmarks)).to eq(bookmarks)
    end

    it 'draws bookmark list' do
      mode.draw(24, 80)
      expect(EbookReader::Terminal).to have_received(:write).at_least(5).times
    end

    it 'handles bookmark navigation' do
      mode.instance_variable_set(:@selected, 0)
      mode.handle_input('j')
      # Navigation is handled by InputHandler mixin
    end

    it 'jumps to selected bookmark' do
      expect(reader).to receive(:send).with(:jump_to_bookmark)
      mode.handle_input("\r")
    end

    it 'deletes selected bookmark' do
      expect(reader).to receive(:send).with(:delete_selected_bookmark)
      allow(reader).to receive(:send).with(:bookmarks).and_return([])
      mode.handle_input('d')
    end

    it 'handles empty bookmarks' do
      allow(reader).to receive(:send).with(:bookmarks).and_return([])
      mode = described_class.new(reader)

      expect(reader).to receive(:switch_mode).with(:read)
      mode.handle_input('B')
    end
  end

  describe EbookReader::ReaderModes::HelpMode do
    let(:mode) { described_class.new(reader) }

    it 'displays help content' do
      mode.draw(24, 80)

      # Verify help content is displayed
      expect(EbookReader::Terminal).to have_received(:write)
        .with(anything, anything, /Navigation Keys:/)
      expect(EbookReader::Terminal).to have_received(:write)
        .with(anything, anything, /View Options:/)
      expect(EbookReader::Terminal).to have_received(:write)
        .with(anything, anything, /Features:/)
    end

    it 'returns to reading mode on any key' do
      expect(reader).to receive(:switch_mode).with(:read)
      mode.handle_input('x')

      expect(reader).to receive(:switch_mode).with(:read)
      mode.handle_input("\r")

      expect(reader).to receive(:switch_mode).with(:read)
      mode.handle_input('?')
    end
  end
end
