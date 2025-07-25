# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/constants'

describe EbookReader::Constants do
  it "defines CONFIG_DIR" do
    expect(EbookReader::Constants::CONFIG_DIR).to eq(File.expand_path("~/.config/ebook_reader"))
  end

  it "defines CONFIG_FILE" do
    expect(EbookReader::Constants::CONFIG_FILE).to eq(File.join(EbookReader::Constants::CONFIG_DIR, "config.yml"))
  end

  it "defines RECENT_FILES_FILE" do
    expect(EbookReader::Constants::RECENT_FILES_FILE).to eq(File.join(EbookReader::Constants::CONFIG_DIR, "recent_files.yml"))
  end

  it "defines BOOKMARKS_FILE" do
    expect(EbookReader::Constants::BOOKMARKS_FILE).to eq(File.join(EbookReader::Constants::CONFIG_DIR, "bookmarks.yml"))
  end

  it "defines PROGRESS_FILE" do
    expect(EbookReader::Constants::PROGRESS_FILE).to eq(File.join(EbookReader::Constants::CONFIG_DIR, "progress.yml"))
  end
end
