# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::MainMenu, 'rendering' do
  let(:menu) { described_class.new }

  before do
    allow(EbookReader::Terminal).to receive(:start_frame)
    allow(EbookReader::Terminal).to receive(:end_frame)
    allow(EbookReader::Terminal).to receive(:write)
    allow(menu).to receive(:loop).and_yield
  end

  context 'when drawing different screens' do
    it 'draws the main menu' do
      menu.instance_variable_set(:@mode, :menu)
      expect(menu).to receive(:draw_main_menu)
      menu.send(:draw_screen)
    end

    it 'draws the browse screen' do
      menu.instance_variable_set(:@mode, :browse)
      expect(menu).to receive(:draw_browse_screen)
      menu.send(:draw_screen)
    end

    it 'draws the recent screen' do
      menu.instance_variable_set(:@mode, :recent)
      allow(EbookReader::RecentFiles).to receive(:load).and_return([])
      expect(menu).to receive(:draw_recent_screen)
      menu.send(:draw_screen)
    end

    it 'draws the settings screen' do
      menu.instance_variable_set(:@mode, :settings)
      expect(menu).to receive(:draw_settings_screen)
      menu.send(:draw_screen)
    end
  end

  context 'when drawing empty states' do
    it 'renders empty recent screen correctly' do
      allow(EbookReader::RecentFiles).to receive(:load).and_return([])
      recent_screen = menu.instance_variable_get(:@recent_screen)
      expect(recent_screen).to receive(:draw).with(24, 80)
      menu.send(:draw_recent_screen, 24, 80)
    end

    it 'renders empty bookmarks screen correctly' do
      reader = EbookReader::Reader.new('/fake.epub')
      reader.instance_variable_set(:@bookmarks, [])
      expect(reader).to receive(:draw_empty_bookmarks)
      reader.send(:draw_bookmarks_screen, 24, 80)
    end
  end
end
