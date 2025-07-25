# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Terminal do
  describe '.start_frame and .end_frame' do
    it 'writes buffered output when ending frame' do
      allow(described_class).to receive(:print)
      allow($stdout).to receive(:flush)
      described_class.start_frame
      described_class.move(1, 1)
      described_class.write(1, 1, 'Hi')
      buffer = described_class.instance_variable_get(:@buffer).dup
      described_class.end_frame
      expect(described_class).to have_received(:print).with(buffer.join)
      expect($stdout).to have_received(:flush)
    end
  end

  describe '.move' do
    it 'adds cursor move sequence to buffer' do
      described_class.start_frame
      described_class.move(5, 10)
      buffer = described_class.instance_variable_get(:@buffer)
      expect(buffer).to include(EbookReader::Terminal::ANSI.move(5, 10))
    end
  end
end
