# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/helpers/epub_scanner'

describe EbookReader::Helpers::EpubScanner, fake_fs: true do
  describe ".scan" do
    before do
      FileUtils.mkdir_p('/epubs/dir1')
      FileUtils.touch('/epubs/book1.epub')
      FileUtils.touch('/epubs/dir1/book2.epub')
      FileUtils.touch('/epubs/not_an_epub.txt')
    end

    it "finds all epub files in a directory" do
      files = described_class.scan('/epubs')
      expect(files).to contain_exactly('/epubs/book1.epub', '/epubs/dir1/book2.epub')
    end

    it "returns an empty array if no epubs are found" do
      FileUtils.mkdir_p('/empty_dir')
      files = described_class.scan('/empty_dir')
      expect(files).to be_empty
    end

    it "handles non-existent directories" do
      files = described_class.scan('/non_existent_dir')
      expect(files).to be_empty
    end
  end
end
