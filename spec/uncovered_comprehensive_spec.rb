# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Uncovered methods comprehensive' do
  describe EbookReader::UI::MainMenuRenderer do
    let(:config) { instance_double(EbookReader::Config) }
    let(:renderer) { described_class.new(config) }

    before do
      allow(EbookReader::Terminal).to receive(:write)
    end

    it 'calculates logo position correctly for small terminals' do
      stub_const('EbookReader::VERSION', 'v1.0')
      menu_start = renderer.render_logo(10, 40)
      expect(menu_start).to eq(2 + 6 + 5) # min start + logo lines + spacing
    end
  end

  describe EbookReader::Terminal::ANSI::Control do
    it 'has all control constants' do
      expect(described_class::CLEAR).not_to be_nil
      expect(described_class::HOME).not_to be_nil
      expect(described_class::HIDE_CURSOR).not_to be_nil
      expect(described_class::SHOW_CURSOR).not_to be_nil
      expect(described_class::SAVE_SCREEN).not_to be_nil
      expect(described_class::RESTORE_SCREEN).not_to be_nil
    end
  end

  describe EbookReader::Concerns::InputHandler do
    let(:handler) { Class.new { include EbookReader::Concerns::InputHandler }.new }

    it 'recognizes all navigation keys' do
      expect(handler.navigation_key?('j')).to be true
      expect(handler.navigation_key?('k')).to be true
      expect(handler.navigation_key?("\e[A")).to be true
      expect(handler.navigation_key?("\e[B")).to be true
      expect(handler.navigation_key?("\eOA")).to be true
      expect(handler.navigation_key?("\eOB")).to be true
      expect(handler.navigation_key?('x')).to be false
    end

    it 'handles OA/OB terminal variants' do
      result = handler.handle_navigation_keys("\eOA", 5, 10)
      expect(result).to eq(4)

      result = handler.handle_navigation_keys("\eOB", 5, 10)
      expect(result).to eq(6)
    end
  end

  describe EbookReader::RecentFiles do
    it 'handles file write errors silently' do
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write).and_raise(Errno::ENOSPC)

      expect { described_class.add('/book.epub') }.not_to raise_error
    end
  end

  describe EbookReader::ProgressManager do
    it 'uses proper time format' do
      path = '/book.epub'
      described_class.save(path, 1, 10)

      progress = described_class.load(path)
      expect { Time.iso8601(progress['timestamp']) }.not_to raise_error
    end
  end

  describe EbookReader::BookmarkManager do
    it 'handles save_all errors gracefully' do
      allow(File).to receive(:write).and_raise(Errno::EIO)

      result = described_class.save_all({})
      expect(result).to be_nil
    end
  end
end
