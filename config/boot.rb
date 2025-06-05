ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

require "json"          # Prevent Ruby 3.3.0 bug before bootsnap initializes
# require "bootsnap/setup" # Disabled due to Ruby 3.3.0 + JSON bug
