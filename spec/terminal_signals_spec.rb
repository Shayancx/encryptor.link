require 'spec_helper'

RSpec.describe "Terminal Signal Handling" do
  it "sets up signal handlers" do
    # Mock trap to avoid actually setting signal handlers
    allow(EbookReader::Terminal).to receive(:trap)
    
    expect(EbookReader::Terminal).to receive(:trap).with("INT")
    expect(EbookReader::Terminal).to receive(:trap).with("TERM")
    
    EbookReader::Terminal.send(:setup_signal_handlers)
  end
end
