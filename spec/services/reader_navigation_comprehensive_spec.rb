require 'spec_helper'

RSpec.describe EbookReader::Services::ReaderNavigation do
  let(:state) { EbookReader::Core::ReaderState.new }
  let(:document) do
    instance_double(EbookReader::EPUBDocument,
                    chapter_count: 3,
                    chapters: [
                      { title: "Ch1", lines: Array.new(50, "line") },
                      { title: "Ch2", lines: Array.new(60, "line") },
                      { title: "Ch3", lines: Array.new(40, "line") }
                    ])
  end
  let(:config) { instance_double(EbookReader::Config, view_mode: :single) }
  let(:navigation) { described_class.new(state, document, config) }
  
  describe 'single view navigation' do
    it 'scrolls down within limits' do
      navigation.scroll_down(10)
      expect(state.single_page).to eq(1)
      
      state.single_page = 10
      navigation.scroll_down(10)
      expect(state.single_page).to eq(10)
    end
    
    it 'scrolls up within limits' do
      state.single_page = 5
      navigation.scroll_up
      expect(state.single_page).to eq(4)
      
      state.single_page = 0
      navigation.scroll_up
      expect(state.single_page).to eq(0)
    end
    
    it 'navigates pages correctly' do
      navigation.next_page(10, 50)
      expect(state.single_page).to eq(10)
      
      state.single_page = 45
      navigation.next_page(10, 50)
      expect(state.single_page).to eq(50)
    end
    
    it 'handles chapter transitions on next' do
      state.single_page = 50
      navigation.next_page(10, 50)
      expect(state.current_chapter).to eq(1)
      expect(state.single_page).to eq(0)
    end
    
    it 'handles chapter transitions on previous' do
      state.current_chapter = 1
      state.single_page = 0
      navigation.previous_page(10)
      expect(state.current_chapter).to eq(0)
    end
  end
  
  describe 'split view navigation' do
    before { allow(config).to receive(:view_mode).and_return(:split) }
    
    it 'scrolls both pages down' do
      navigation.scroll_down(20)
      expect(state.left_page).to eq(1)
      expect(state.right_page).to eq(1)
    end
    
    it 'scrolls both pages up' do
      state.left_page = 5
      state.right_page = 5
      navigation.scroll_up
      expect(state.left_page).to eq(4)
      expect(state.right_page).to eq(4)
    end
    
    it 'handles split view page navigation' do
      navigation.next_page(10, 50)
      expect(state.left_page).to eq(0)
      expect(state.right_page).to eq(10)
      
      navigation.next_page(10, 50)
      expect(state.left_page).to eq(10)
      expect(state.right_page).to eq(20)
    end
  end
  
  describe 'chapter navigation' do
    it 'validates chapter boundaries' do
      expect(navigation.can_go_to_next_chapter?).to be true
      state.current_chapter = 2
      expect(navigation.can_go_to_next_chapter?).to be false
      
      expect(navigation.can_go_to_previous_chapter?).to be true
      state.current_chapter = 0
      expect(navigation.can_go_to_previous_chapter?).to be false
    end
    
    it 'jumps to specific chapters' do
      navigation.jump_to_chapter(2)
      expect(state.current_chapter).to eq(2)
      expect(state.single_page).to eq(0)
      
      navigation.jump_to_chapter(-1)
      expect(state.current_chapter).to eq(2) # Should not change
      
      navigation.jump_to_chapter(5)
      expect(state.current_chapter).to eq(2) # Should not change
    end
  end
  
  describe 'position management' do
    it 'goes to start of chapter' do
      state.single_page = 25
      navigation.go_to_start
      expect(state.single_page).to eq(0)
    end
    
    it 'goes to end of chapter' do
      navigation.go_to_end(10, 45)
      expect(state.single_page).to eq(45)
    end
    
    it 'handles split view end position' do
      allow(config).to receive(:view_mode).and_return(:split)
      navigation.go_to_end(10, 45)
      expect(state.right_page).to eq(45)
      expect(state.left_page).to eq(35)
    end
  end
end
