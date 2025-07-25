# Changelog

All notable changes to Simple Novel Reader will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive documentation with YARD
- Architecture documentation
- Command pattern for input handling
- Strategy pattern for reader modes
- Dedicated error classes
- Constants configuration module
- Rendering components separation

### Changed
- Refactored Reader class to use mode handlers
- Extracted magic numbers to constants
- Improved error handling with context
- Modularized rendering logic

### Fixed
- Terminal size validation
- Memory efficiency in large documents
- Input handling edge cases

## [0.9.212-beta] - Previous Release

### Added
- Initial implementation
- Basic EPUB reading functionality
- Bookmark support
- Progress tracking
