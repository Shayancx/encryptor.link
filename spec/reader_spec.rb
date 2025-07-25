require 'spec_helper'

RSpec.describe EbookReader::Reader do
  let(:epub_path) { '/book.epub' }
  let(:config) { instance_double(EbookReader::Config, view_mode: :split) }
  let(:doc) do
    instance_double(EbookReader::EPUBDocument,
      title: "Test Book",
      chapters: [{ title: "Ch1", lines: ["Line 1", "Line 2"] }],
      chapter_count: 1
    )
  end

  let(:reader) { described_class.new(epub_path, config) }

  before do
    allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
    allow(doc).to receive(:get_chapter).and_return(doc.chapters.first)
    allow(EbookReader::Terminal).to receive(:setup)
    allow(EbookReader::Terminal).to receive(:cleanup)
    allow(EbookReader::Terminal).to receive(:read_key).and_return('q')
    allow(reader).to receive(:loop).and_yield
  end

  describe "#run" do
    it "sets up terminal" do
      expect(EbookReader::Terminal).to receive(:setup)
      reader.run
    end

    it "cleans up terminal on exit" do
      expect(EbookReader::Terminal).to receive(:cleanup)
      reader.run
    end
  end

  describe "navigation" do
    before do
      reader.instance_variable_set(:@running, true)
    end

    it "scrolls down on j key" do
      initial = reader.instance_variable_get(:@single_page)
      reader.send(:handle_reading_input, 'j')
      expect(reader.instance_variable_get(:@single_page)).to be >= initial
    end

    it "scrolls up on k key" do
      reader.instance_variable_set(:@single_page, 5)
      reader.send(:handle_reading_input, 'k')
      expect(reader.instance_variable_get(:@single_page)).to eq(4)
    end

    it "goes to next chapter on n key" do
      allow(doc).to receive(:chapter_count).and_return(2)
      reader.send(:handle_reading_input, 'n')
      expect(reader.instance_variable_get(:@current_chapter)).to eq(1)
    end

    it "adds bookmark on b key" do
      expect(reader).to receive(:add_bookmark)
      reader.send(:handle_reading_input, 'b')
    end

    it "toggles view mode on v key" do
      expect(config).to receive(:view_mode=).with(:single)
      expect(config).to receive(:save)
      reader.send(:handle_reading_input, 'v')
    end
  end

  describe "bookmarks" do
    it "loads bookmarks on init" do
      expect(EbookReader::BookmarkManager).to receive(:get).with(epub_path)
      described_class.new(epub_path, config)
    end

    it "adds bookmark with current position" do
      expect(EbookReader::BookmarkManager).to receive(:add).with(
        epub_path, 0, 0, anything
      )
      reader.send(:add_bookmark)
    end
  end

  describe "progress" do
    it "loads progress on init" do
      expect(EbookReader::ProgressManager).to receive(:load).with(epub_path)
      described_class.new(epub_path, config)
    end

    it "saves progress on quit" do
      expect(EbookReader::ProgressManager).to receive(:save).with(
        epub_path, 0, 0
      )
      reader.send(:quit_to_menu)
    end
  end
end
