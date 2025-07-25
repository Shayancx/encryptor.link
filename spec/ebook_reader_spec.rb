# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader'

describe EbookReader do
  it "loads the necessary classes" do
    expect(defined?(EbookReader::Cli)).to be_truthy
    expect(defined?(EbookReader::MainMenu)).to be_truthy
    expect(defined?(EbookReader::Reader)).to be_truthy
  end
end
