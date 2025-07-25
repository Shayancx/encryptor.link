# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/concerns/input_handler'

describe EbookReader::Concerns::InputHandler do
  let(:dummy_class) do
    Class.new do
      include EbookReader::Concerns::InputHandler
    end
  end

  let(:instance) { dummy_class.new }

  describe "#handle_input" do
    it "returns the key for a single character" do
      allow(STDIN).to receive(:getch).and_return("a")
      expect(instance.handle_input).to eq("a")
    end

    it "handles escape sequences" do
      allow(STDIN).to receive(:getch).and_return("\e")
      allow(STDIN).to receive(:read_nonblock).and_return("[A", nil)
      expect(instance.handle_input).to eq("\e[A")
    end

    it "handles resize signal" do
      allow(STDIN).to receive(:getch).and_return("\u0012") # Ctrl-R for resize
      expect(instance.handle_input).to eq(:resize)
    end
  end
end
