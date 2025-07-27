# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Terminal, 'comprehensive' do
  describe 'ANSI module' do
    it 'has all required constants' do
      expect(described_class::ANSI::BOLD).to eq("\e[1m")
      expect(described_class::ANSI::DIM).to eq("\e[2m")
      expect(described_class::ANSI::ITALIC).to eq("\e[3m")
      expect(described_class::ANSI::BLACK).to eq("\e[30m")
      expect(described_class::ANSI::YELLOW).to eq("\e[33m")
      expect(described_class::ANSI::CYAN).to eq("\e[36m")
      expect(described_class::ANSI::WHITE).to eq("\e[37m")
    end

    it 'generates correct move sequences' do
      expect(described_class::ANSI.move(1, 1)).to eq("\e[1;1H")
      expect(described_class::ANSI.move(99, 99)).to eq("\e[99;99H")
    end

    it 'generates correct clear sequences' do
      expect(described_class::ANSI.clear_line).to eq("\e[2K")
      expect(described_class::ANSI.clear_below).to eq("\e[J")
    end
  end

  describe '.setup and .cleanup integration' do
    it 'properly sets up and tears down terminal' do
      expect($stdout).to receive(:sync=).with(true)
      expect(described_class).to receive(:trap).twice
      described_class.setup
    end
  end
end
