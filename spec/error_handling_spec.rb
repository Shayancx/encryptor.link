require 'spec_helper'

RSpec.describe "Error Handling" do
  describe EbookReader::Config do
    it "handles file write errors gracefully" do
      config = described_class.new
      allow(File).to receive(:write).and_raise(Errno::EACCES)
      
      # Should not raise
      expect { config.save }.not_to raise_error
    end
  end

  describe EbookReader::BookmarkManager do
    it "returns empty array on corrupted bookmark file" do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).and_return("invalid json{")
      
      expect(described_class.load_all).to eq({})
    end
  end

  describe EbookReader::RecentFiles do
    it "handles file system errors when saving" do
      allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::EACCES)
      
      # Should not raise
      expect { described_class.add("/book.epub") }.not_to raise_error
    end
  end

  describe EbookReader::Terminal do
    it "handles terminal size errors" do
      allow(IO.console).to receive(:winsize).and_raise(StandardError)
      expect(described_class.size).to eq([24, 80])
    end
  end
end
