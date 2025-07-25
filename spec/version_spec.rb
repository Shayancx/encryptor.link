# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/version'

describe EbookReader do
  it "has a version number" do
    expect(EbookReader::VERSION).not_to be nil
  end
end
