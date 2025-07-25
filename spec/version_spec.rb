require 'spec_helper'

RSpec.describe "EbookReader::VERSION" do
  it "has a version number" do
    expect(EbookReader::VERSION).not_to be nil
  end

  it "follows semantic versioning format" do
    expect(EbookReader::VERSION).to match(/\Av?\d+\.\d+\.\d+/)
  end

  it "contains the expected version string" do
    expect(EbookReader::VERSION).to eq('v0.9.212-beta')
  end
end
