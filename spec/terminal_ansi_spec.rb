# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Terminal::ANSI do
  describe 'text styling constants' do
    it 'defines text styling codes' do
      expect(described_class::BOLD).to eq("\e[1m")
      expect(described_class::DIM).to eq("\e[2m")
      expect(described_class::ITALIC).to eq("\e[3m")
    end
  end

  describe 'bright color constants' do
    it 'defines bright color codes' do
      expect(described_class::BRIGHT_RED).to eq("\e[91m")
      expect(described_class::BRIGHT_GREEN).to eq("\e[92m")
      expect(described_class::BRIGHT_YELLOW).to eq("\e[93m")
      expect(described_class::BRIGHT_BLUE).to eq("\e[94m")
      expect(described_class::BRIGHT_MAGENTA).to eq("\e[95m")
      expect(described_class::BRIGHT_CYAN).to eq("\e[96m")
      expect(described_class::BRIGHT_WHITE).to eq("\e[97m")
    end
  end

  describe 'background colors' do
    it 'defines background color codes' do
      expect(described_class::BG_DARK).to eq("\e[48;5;236m")
    end
  end

  describe '.clear_below' do
    it 'returns clear below sequence' do
      expect(described_class.clear_below).to eq("\e[J")
    end
  end
end

RSpec.describe EbookReader::Terminal::ANSI::Control do
  it 'defines control sequences' do
    expect(described_class::CLEAR).to eq("\e[2J")
    expect(described_class::HOME).to eq("\e[H")
    expect(described_class::HIDE_CURSOR).to eq("\e[?25l")
    expect(described_class::SHOW_CURSOR).to eq("\e[?25h")
    expect(described_class::SAVE_SCREEN).to eq("\e[?1049h")
    expect(described_class::RESTORE_SCREEN).to eq("\e[?1049l")
  end
end
