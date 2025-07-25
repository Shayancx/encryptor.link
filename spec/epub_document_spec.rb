# frozen_string_literal: true
require 'spec_helper'
require 'zip'
require_relative '../lib/ebook_reader/epub_document'

describe EbookReader::EpubDocument, fake_fs: true do
  let(:epub_path) { '/book.epub' }
  let(:opf_path) { 'OPS/content.opf' }
  let(:html_path1) { 'OPS/chapter1.html' }
  let(:html_path2) { 'OPS/chapter2.html' }

  before do
    # Create a fake epub file for testing
    Zip::File.open(epub_path, Zip::File::CREATE) do |zipfile|
      zipfile.get_output_stream("mimetype") { |f| f.write "application/epub+zip" }
      zipfile.get_output_stream("META-INF/container.xml") do |f|
        f.write <<-XML
          <container>
            <rootfiles>
              <rootfile full-path="#{opf_path}" media-type="application/oebps-package+xml" />
            </rootfiles>
          </container>
        XML
      end
      zipfile.get_output_stream(opf_path) do |f|
        f.write <<-OPF
          <package>
            <manifest>
              <item id="item1" href="chapter1.html" media-type="application/xhtml+xml" />
              <item id="item2" href="chapter2.html" media-type="application/xhtml+xml" />
            </manifest>
            <spine>
              <itemref idref="item1" />
              <itemref idref="item2" />
            </spine>
          </package>
        OPF
      end
      zipfile.get_output_stream(html_path1) { |f| f.write "<html><body><h1>Chapter 1</h1><p>Page 1</p></body></html>" }
      zipfile.get_output_stream(html_path2) { |f| f.write "<html><body><h1>Chapter 2</h1><p>Page 2</p></body></html>" }
    end
  end

  let(:document) { described_class.new(epub_path, 80, 24) }

  describe "#initialize" do
    it "loads the epub file" do
      expect(document.path).to eq(epub_path)
    end

    it "parses the content" do
      expect(document.total_pages).to eq(2)
    end
  end

  describe "#page_content" do
    it "returns the content for a given page" do
      expect(document.page_content(0)).to include("Chapter 1")
      expect(document.page_content(1)).to include("Chapter 2")
    end

    it "returns nil for an invalid page" do
      expect(document.page_content(5)).to be_nil
    end
  end

  describe "navigation" do
    it "goes to the next page" do
      document.next_page
      expect(document.current_page_index).to eq(1)
    end

    it "does not go past the last page" do
      document.current_page_index = 1
      document.next_page
      expect(document.current_page_index).to eq(1)
    end

    it "goes to the previous page" do
      document.current_page_index = 1
      document.previous_page
      expect(document.current_page_index).to eq(0)
    end

    it "does not go before the first page" do
      document.previous_page
      expect(document.current_page_index).to eq(0)
    end
  end
end
