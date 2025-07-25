require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end

require 'rspec'
require 'fakefs/spec_helpers'
require_relative '../lib/ebook_reader'

# frozen_string_literal: true

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FakeFS::SpecHelpers, fake_fs: true
end
