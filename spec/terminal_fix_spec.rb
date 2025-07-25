# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Terminal Fix" do
  before do
    stub_const(
      "EbookReader::Terminal",
      Class.new do
        define_singleton_method(:get_key) { "test_key" }
      end
    )

    # Apply the fix
    load File.expand_path('../lib/ebook_reader/terminal_fix.rb', __dir__)
  end

  it "aliases get_key to read_key" do
    expect(EbookReader::Terminal).to respond_to(:read_key)
    expect(EbookReader::Terminal.read_key).to eq("test_key")
  end

  it "removes get_key method" do
    expect(EbookReader::Terminal).not_to respond_to(:get_key)
  end
end
