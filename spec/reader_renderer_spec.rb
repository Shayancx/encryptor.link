# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/ui/reader_renderer'

describe EbookReader::Ui::ReaderRenderer do
  let(:terminal) { double("EbookReader::Terminal", width: 80, height: 24, clear: nil, move_to: nil, print: nil) }
  let(:reader) do
    double(
      "EbookReader::Reader",
      document: double("EbookReader::EpubDocument", path: "/book.epub", current_page_index: 0, total_pages: 10),
      percentage_finished: 10,
      bookmarked?: false
    )
  end
  let(:renderer) { described_class.new(reader, terminal) }

  before do
    allow(reader.document).to receive(:page_content).and_return("Page content")
  end

  describe "#render" do
    it "clears the terminal" do
      expect(terminal).to receive(:clear)
      renderer.render
    end

    it "prints the page content" do
      expect(terminal).to receive(:print).with("Page content")
      renderer.render
    end

    it "prints the status bar" do
      expect(terminal).to receive(:print).with(/book.epub/)
      expect(terminal).to receive(:print).with(/1\/10/)
      expect(terminal).to receive(:print).with(/10%/)
      renderer.render
    end

    it "indicates when a page is bookmarked" do
      allow(reader).to receive(:bookmarked?).and_return(true)
      expect(terminal).to receive(:print).with(/\[B\]/)
      renderer.render
    end
  end
end
