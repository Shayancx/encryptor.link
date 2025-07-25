# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/terminal'

describe EbookReader::Terminal do
  let(:io_console) { double("IO.console") }
  let(:stdout) { double("STDOUT") }
  let(:terminal) { described_class.new }

  before do
    stub_const("IO.console", io_console)
    stub_const("STDOUT", stdout)
    allow(io_console).to receive(:winsize).and_return([24, 80])
    allow(stdout).to receive(:print)
  end

  describe "#clear" do
    it "prints the clear screen sequence" do
      expect(stdout).to receive(:print).with("\e[2J\e[H")
      terminal.clear
    end
  end

  describe "#move_to" do
    it "prints the move cursor sequence" do
      expect(stdout).to receive(:print).with("\e[10;20H")
      terminal.move_to(10, 20)
    end
  end

  describe "#width" do
    it "returns the terminal width" do
      expect(terminal.width).to eq(80)
    end
  end

  describe "#height" do
    it "returns the terminal height" do
      expect(terminal.height).to eq(24)
    end
  end

  describe "#raw_mode" do
    it "sets the terminal to raw mode" do
      expect(io_console).to receive(:raw!)
      terminal.raw_mode
    end
  end

  describe "#cooked_mode" do
    it "sets the terminal to cooked mode" do
      expect(io_console).to receive(:cooked!)
      terminal.cooked_mode
    end
  end
end
