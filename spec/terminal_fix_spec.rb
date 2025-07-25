# frozen_string_literal: true
require 'spec_helper'

describe "TerminalFix" do
  before do
    # Define a dummy class that the fix can be applied to
    class EbookReader::Terminal
      def self.get_key
        "key"
      end
    end

    # Load the fix
    require_relative '../lib/ebook_reader/terminal_fix'
  end

  it "aliases get_key to read_key" do
    expect(EbookReader::Terminal).to respond_to(:read_key)
  end

  it "removes the get_key method" do
    expect(EbookReader::Terminal).not_to respond_to(:get_key)
  end

  it "read_key returns the correct value" do
    expect(EbookReader::Terminal.read_key).to eq("key")
  end
end
