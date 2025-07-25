# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Constants do
  it "defines CONFIG_DIR" do
    expect(described_class::CONFIG_DIR).to eq(File.expand_path("~/.config/simple-novel-reader"))
  end

  it "defines ESCAPE_CHAR" do
    expect(described_class::ESCAPE_CHAR).to eq("\e")
  end

  it "defines ESCAPE_CODE" do
    expect(described_class::ESCAPE_CODE).to eq("\x1B")
  end

  it "defines SCAN_TIMEOUT" do
    expect(described_class::SCAN_TIMEOUT).to eq(20)
  end

  it "defines MAX_DEPTH" do
    expect(described_class::MAX_DEPTH).to eq(3)
  end

  it "defines MAX_FILES" do
    expect(described_class::MAX_FILES).to eq(500)
  end

  it "defines MAX_LINE_LENGTH" do
    expect(described_class::MAX_LINE_LENGTH).to eq(120)
  end

  it "defines SKIP_DIRS" do
    expect(described_class::SKIP_DIRS).to be_an(Array)
    expect(described_class::SKIP_DIRS).to include('node_modules', 'vendor', 'cache')
  end
end
