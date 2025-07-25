# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/epub_finder'

describe EbookReader::EpubFinder, fake_fs: true do
  let(:config) do
    double("EbookReader::Config", search_paths: ['/epubs'], cache_epub_paths: true)
  end
  let(:finder) { described_class.new(config) }
  let(:cache_path) { File.join(EbookReader::Constants::CONFIG_DIR, "epub_cache.yml") }

  before do
    FileUtils.mkdir_p('/epubs/dir1')
    FileUtils.touch('/epubs/book1.epub')
    FileUtils.touch('/epubs/dir1/book2.epub')
    FileUtils.mkdir_p(EbookReader::Constants::CONFIG_DIR)
  end

  describe "#epubs" do
    it "finds all epub files" do
      expect(finder.epubs).to contain_exactly('/epubs/book1.epub', '/epubs/dir1/book2.epub')
    end

    it "caches the epub paths" do
      finder.epubs
      expect(File.exist?(cache_path)).to be true
      cached_epubs = YAML.load_file(cache_path)
      expect(cached_epubs).to contain_exactly('/epubs/book1.epub', '/epubs/dir1/book2.epub')
    end

    it "loads from cache if available" do
      cached_data = ['/cached/book.epub']
      File.write(cache_path, cached_data.to_yaml)
      expect(finder.epubs).to eq(cached_data)
    end

    it "does not use cache if disabled" do
      allow(config).to receive(:cache_epub_paths).and_return(false)
      finder.epubs
      expect(File.exist?(cache_path)).to be false
    end
  end

  describe "#clear_cache" do
    it "clears the cache file" do
      File.write(cache_path, ['/cached/book.epub'].to_yaml)
      finder.clear_cache
      expect(File.exist?(cache_path)).to be false
    end
  end
end
