# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Terminal do
  describe '.start_frame and .end_frame' do
    it 'writes buffered output when ending frame' do
      allow(described_class).to receive(:start_frame).and_call_original
      allow(described_class).to receive(:end_frame).and_call_original
      allow(described_class).to receive(:clear).and_call_original
      expect(described_class).to receive(:print) # from end_frame
      expect($stdout).to receive(:flush)
      described_class.start_frame
      described_class.move(1, 1)
      described_class.write(1, 1, 'Hi')
      described_class.instance_variable_get(:@buffer).dup
      described_class.end_frame
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

  describe '.read_key' do
    it 'returns escape when sequence is incomplete' do
      allow(described_class).to receive(:read_key).and_call_original
      console = double('console')
      allow(console).to receive(:raw).and_yield
      allow(IO).to receive(:console).and_return(console)
      call = 0
      allow($stdin).to receive(:read_nonblock) do
        call += 1
        raise IO::EAGAINWaitReadable if call > 1

        "\e"
      end
      expect(described_class.read_key).to eq("\e")
    end

    it 'raises error when console is unavailable' do
      allow(described_class).to receive(:read_key).and_call_original
      allow(IO).to receive(:console).and_return(nil)
      expect { described_class.read_key }.to raise_error(EbookReader::TerminalUnavailableError)
    end
  end

  describe '.size' do
    it 'falls back when winsize is nil' do
      allow(IO.console).to receive(:winsize).and_return(nil)
      expect(described_class.size).to eq([24, 80])
    end
  end
end
