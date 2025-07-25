require 'spec_helper'

RSpec.describe "Integration Tests" do
  describe "Full application flow" do
    it "can create all main components" do
      # Test that all main components can be instantiated
      expect { EbookReader::Config.new }.not_to raise_error
      expect { EbookReader::Terminal }.not_to raise_error
      expect { EbookReader::BookmarkManager }.not_to raise_error
      expect { EbookReader::ProgressManager }.not_to raise_error
      expect { EbookReader::RecentFiles }.not_to raise_error
    end

    it "loads all modules correctly" do
      # Verify module structure
      expect(EbookReader::Helpers).to be_a(Module)
      expect(EbookReader::UI).to be_a(Module)
      expect(EbookReader::Concerns).to be_a(Module)
      expect(EbookReader::Constants).to be_a(Module)
    end
  end

  describe "Config lifecycle" do
    it "can save and reload configuration", fake_fs: true do
      # Create and save config
      config1 = EbookReader::Config.new
      config1.view_mode = :single
      config1.line_spacing = :relaxed
      config1.save

      # Load in new instance
      config2 = EbookReader::Config.new
      expect(config2.view_mode).to eq(:single)
      expect(config2.line_spacing).to eq(:relaxed)
    end
  end
end
