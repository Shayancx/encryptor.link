# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/main_menu'

describe EbookReader::MainMenu do
  let(:terminal) { double("EbookReader::Terminal", raw_mode: nil, cooked_mode: nil) }
  let(:config) { double("EbookReader::Config") }
  let(:main_menu) { described_class.new(config: config, terminal: terminal) }

  before do
    allow(main_menu).to receive(:loop).and_yield
    allow(main_menu).to receive(:handle_input).and_return(nil) # Default to no action
    allow(main_menu).to receive(:render)
    allow(main_menu).to receive(:exit)
  end

  describe "#run" do
    it "renders the menu" do
      expect(main_menu).to receive(:render)
      main_menu.run
    end

    it "handles input" do
      expect(main_menu).to receive(:handle_input)
      main_menu.run
    end
  end

  describe "input handling" do
    it "moves selection down" do
      main_menu.handle_keypress("\e[B")
      expect(main_menu.selected_index).to eq(1)
    end

    it "moves selection up" do
      main_menu.selected_index = 1
      main_menu.handle_keypress("\e[A")
      expect(main_menu.selected_index).to eq(0)
    end

    it "selects an option on enter" do
      expect(main_menu).to receive(:execute_action)
      main_menu.handle_keypress("\r")
    end
  end

  describe "#execute_action" do
    it "calls browse_for_book when 'Open Book' is selected" do
      main_menu.selected_index = 0
      expect(main_menu).to receive(:browse_for_book)
      main_menu.execute_action
    end

    it "calls show_recent_files when 'Recent Files' is selected" do
      main_menu.selected_index = 1
      expect(main_menu).to receive(:show_recent_files)
      main_menu.execute_action
    end

    it "exits when 'Exit' is selected" do
      main_menu.selected_index = 2
      expect(main_menu).to receive(:exit)
      main_menu.execute_action
    end
  end
end
