require 'spec_helper'

RSpec.describe "Terminal Fix" do
  before do
    # Create a test class with get_key method
    module EbookReader
      class Terminal
        def self.get_key
          "test_key"
        end
      end
    end
    
    # Apply the fix
    load File.expand_path('../../lib/ebook_reader/terminal_fix.rb', __FILE__)
  end

  it "aliases get_key to read_key" do
    expect(EbookReader::Terminal).to respond_to(:read_key)
    expect(EbookReader::Terminal.read_key).to eq("test_key")
  end

  it "removes get_key method" do
    expect(EbookReader::Terminal).not_to respond_to(:get_key)
  end
end
