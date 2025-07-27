# frozen_string_literal: true

require_relative 'lib/ebook_reader/version'

Gem::Specification.new do |spec|
  spec.name = 'reader'
  spec.version = EbookReader::VERSION
  spec.authors = ['Your Name']
  spec.email = ['your.email@example.com']

  spec.summary = 'A fast, keyboard-driven terminal EPUB reader'
  spec.description = 'Reader provides a distraction-free reading experience for EPUB files in your terminal with Vim-style navigation.'
  spec.homepage = 'https://github.com/yourusername/reader'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = 'bin'
  spec.executables = ['ebook_reader']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'rexml', '~> 3.2'
  spec.add_dependency 'rubyzip', '~> 2.3'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'fakefs', '~> 2.5'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'reek', '~> 6.1'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
