# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Concerns::InputHandler do
  let(:test_class) do
    Class.new do
      include EbookReader::Concerns::InputHandler
    end
  end

  let(:handler) { test_class.new }

  describe "#handle_navigation_keys" do
    it "moves down with j key" do
      result = handler.handle_navigation_keys('j', 0, 10)
      expect(result).to eq(1)
    end

    it "moves up with k key" do
      result = handler.handle_navigation_keys('k', 5, 10)
      expect(result).to eq(4)
    end

    it "respects max boundary" do
      result = handler.handle_navigation_keys('j', 10, 10)
      expect(result).to eq(10)
    end

    it "respects min boundary" do
      result = handler.handle_navigation_keys('k', 0, 10)
      expect(result).to eq(0)
    end

    it "handles arrow keys" do
      expect(handler.handle_navigation_keys("\e[B", 0, 10)).to eq(1)
      expect(handler.handle_navigation_keys("\e[A", 5, 10)).to eq(4)
    end
  end

  describe "#escape_key?" do
    it "recognizes escape keys" do
      expect(handler.escape_key?("\e")).to be true
      expect(handler.escape_key?("\x1B")).to be true
      expect(handler.escape_key?('q')).to be true
      expect(handler.escape_key?('a')).to be false
    end
  end

  describe "#enter_key?" do
    it "recognizes enter keys" do
      expect(handler.enter_key?("\r")).to be true
      expect(handler.enter_key?("\n")).to be true
      expect(handler.enter_key?('a')).to be false
    end
  end

  describe "#backspace_key?" do
    it "recognizes backspace keys" do
      expect(handler.backspace_key?("\b")).to be true
      expect(handler.backspace_key?("\x7F")).to be true
      expect(handler.backspace_key?("\x08")).to be true
      expect(handler.backspace_key?('a')).to be false
    end
  end
end
