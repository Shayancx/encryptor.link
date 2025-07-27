# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Core::ReaderState do
  let(:state) { described_class.new }

  describe 'initialization' do
    it 'sets default values' do
      expect(state.current_chapter).to eq(0)
      expect(state.left_page).to eq(0)
      expect(state.right_page).to eq(0)
      expect(state.single_page).to eq(0)
      expect(state.mode).to eq(:read)
      expect(state.running).to be true
    end
  end

  describe '#current_page_offset' do
    it 'returns correct offset for split view' do
      state.left_page = 10
      state.single_page = 5
      expect(state.current_page_offset(:split)).to eq(10)
    end

    it 'returns correct offset for single view' do
      state.left_page = 10
      state.single_page = 5
      expect(state.current_page_offset(:single)).to eq(5)
    end
  end

  describe '#page_offset=' do
    it 'sets all page offsets' do
      state.page_offset = 15
      expect(state.single_page).to eq(15)
      expect(state.left_page).to eq(15)
      expect(state.right_page).to eq(15)
    end
  end

  describe '#terminal_size_changed?' do
    it 'detects size changes' do
      state.update_terminal_size(80, 24)
      expect(state.terminal_size_changed?(80, 24)).to be false
      expect(state.terminal_size_changed?(100, 24)).to be true
      expect(state.terminal_size_changed?(80, 30)).to be true
    end
  end

  describe '#to_h and #restore_from' do
    it 'creates and restores snapshots' do
      state.current_chapter = 5
      state.page_offset = 20
      state.mode = :toc

      snapshot = state.to_h
      expect(snapshot[:current_chapter]).to eq(5)
      expect(snapshot[:page_offset]).to eq(20)
      expect(snapshot[:mode]).to eq(:toc)
      expect(snapshot[:timestamp]).not_to be_nil

      new_state = described_class.new
      new_state.restore_from(snapshot.transform_keys(&:to_s))
      expect(new_state.current_chapter).to eq(5)
      expect(new_state.single_page).to eq(20)
      expect(new_state.mode).to eq(:toc)
    end
  end

  describe '#reset_to_defaults' do
    it 'resets all values to initial state' do
      state.current_chapter = 10
      state.page_offset = 50
      state.mode = :help
      state.running = false

      state.reset_to_defaults

      expect(state.current_chapter).to eq(0)
      expect(state.single_page).to eq(0)
      expect(state.mode).to eq(:read)
      expect(state.running).to be true
    end
  end
end
