# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/helpers/reader_helpers'

describe EbookReader::Helpers::ReaderHelpers do
  let(:dummy_class) do
    Class.new do
      include EbookReader::Helpers::ReaderHelpers
      attr_accessor :document, :terminal, :progress_manager, :bookmark_manager

      def initialize
        @document = double("EbookReader::EpubDocument")
        @terminal = double("EbookReader::Terminal")
        @progress_manager = double("EbookReader::ProgressManager")
        @bookmark_manager = double("EbookReader::BookmarkManager")
      end
    end
  end

  let(:instance) { dummy_class.new }

  describe "#percentage_finished" do
    it "calculates the correct percentage" do
      allow(instance.document).to receive(:total_pages).and_return(10)
      allow(instance.document).to receive(:current_page_index).and_return(4)
      expect(instance.percentage_finished).to eq(40)
    end

    it "handles division by zero" do
      allow(instance.document).to receive(:total_pages).and_return(0)
      expect(instance.percentage_finished).to eq(0)
    end
  end

  describe "#toggle_bookmark" do
    it "adds a bookmark if one does not exist" do
      allow(instance.document).to receive(:path).and_return("path/to/book")
      allow(instance.document).to receive(:current_page_index).and_return(5)
      allow(instance.bookmark_manager).to receive(:has_bookmark?).with("path/to/book", 5).and_return(false)
      expect(instance.bookmark_manager).to receive(:add_bookmark).with("path/to/book", 5)
      instance.toggle_bookmark
    end

    it "removes a bookmark if one exists" do
      allow(instance.document).to receive(:path).and_return("path/to/book")
      allow(instance.document).to receive(:current_page_index).and_return(5)
      allow(instance.bookmark_manager).to receive(:has_bookmark?).with("path/to/book", 5).and_return(true)
      expect(instance.bookmark_manager).to receive(:remove_bookmark).with("path/to/book", 5)
      instance.toggle_bookmark
    end
  end
end
