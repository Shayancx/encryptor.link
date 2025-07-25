# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "CLI Binary" do
  it "calls CLI.run when executed" do
    expect(EbookReader::CLI).to receive(:run)

    # Simulate running the binary
    $LOAD_PATH.unshift File.expand_path('../lib', __dir__)
    load File.expand_path('../bin/ebook_reader', __dir__)
  end
end
