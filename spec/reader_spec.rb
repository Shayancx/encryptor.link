# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/reader'

describe EbookReader::Reader do
  let(:book_path) { '/book.epub' }
  let(:terminal) { double("EbookReader::Terminal", width: 80, height: 24, raw_mode: nil, cooked_mode: nil) }
  let(:document) { double("EbookReader::EpubDocument", path: book_path, current_page_index: 0, total_pages: 10) }
  let(:progress_manager) { double("EbookReader::ProgressManager", progress_for: 0, update_progress: nil, save: nil) }
  let(:bookmark_manager) { double("EbookReader::BookmarkManager", bookmarks_for: [], has_bookmark?: false) }
  let(:reader) do
    described_class.new(
      book_path: book_path,
      terminal: terminal,
      progress_manager: progress_manager,
      bookmark_manager: bookmark_manager
    )
  end

  before do
    allow(EbookReader::EpubDocument).to receive(:new).and_return(document)
    allow(reader).to receive(:loop).and_yield
    allow(reader).to receive(:handle_input).and_return("q") # Default to quit to avoid infinite loop
    allow(reader).to receive(:render)
  end

  describe "#run" do
    it "renders the reader" do
      expect(reader).to receive(:render)
      reader.run
    end

    it "handles input" do
      expect(reader).to receive(:handle_input)
      reader.run
    end

    it "saves progress on quit" do
      allow(reader).to receive(:handle_input).and_return("q")
      expect(progress_manager).to receive(:save)
      reader.run
    end
  end

  describe "input handling" do
    it "quits on 'q'" do
      expect(reader.handle_keypress("q")).to be_nil
    end

    it "goes to the next page on 'j' or down arrow" do
      expect(document).to receive(:next_page).twice
      reader.handle_keypress("j")
      reader.handle_keypress("\e[B")
    end

    it "goes to the previous page on 'k' or up arrow" do
      expect(document).to receive(:previous_page).twice
      reader.handle_keypress("k")
      reader.handle_keypress("\e[A")
    end

    it "toggles a bookmark on 'b'" do
      expect(reader).to receive(:toggle_bookmark)
      reader.handle_keypress("b")
    end
  end
end
