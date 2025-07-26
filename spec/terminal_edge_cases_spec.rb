# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Terminal, "edge cases" do
  describe '.read_key' do
    it 'handles partial escape sequences' do
      allow(EbookReader::Terminal).to receive(:read_key).and_call_original
      console = double('console')
      allow(console).to receive(:raw).and_yield
      allow(IO).to receive(:console).and_return(console)
      attempts = 0
      allow($stdin).to receive(:read_nonblock) do |_size|
        attempts += 1
        case attempts
        when 1 then "\e"
        when 2 then "["
        else raise IO::EAGAINWaitReadable
        end
      end

      key = described_class.read_key
      expect(key).to start_with("\e")
    end

    it 'handles multi-byte escape sequences' do
      allow(EbookReader::Terminal).to receive(:read_key).and_call_original
      console = double('console')
      allow(console).to receive(:raw).and_yield
      allow(IO).to receive(:console).and_return(console)
      allow($stdin).to receive(:read_nonblock).with(1).and_return("\e")
      allow($stdin).to receive(:read_nonblock).with(3).and_return("[1~")

      expect(described_class.read_key).to eq("\e[1~")
    end
  end

  describe '.write' do
    it 'handles nil text gracefully' do
      allow(EbookReader::Terminal).to receive(:start_frame).and_call_original
      allow(EbookReader::Terminal).to receive(:write).and_call_original
      allow(EbookReader::Terminal).to receive(:start_frame).and_call_original
      allow(EbookReader::Terminal).to receive(:write).and_call_original
      described_class.start_frame
      expect { described_class.write(1, 1, nil) }.not_to raise_error
    end

    it 'handles empty text' do
      allow(EbookReader::Terminal).to receive(:start_frame).and_call_original
      allow(EbookReader::Terminal).to receive(:write).and_call_original
      described_class.start_frame
      expect { described_class.write(1, 1, "") }.not_to raise_error
    end

    it 'converts non-string objects to string' do
      allow(EbookReader::Terminal).to receive(:start_frame).and_call_original
      allow(EbookReader::Terminal).to receive(:write).and_call_original
      described_class.start_frame
      expect { described_class.write(1, 1, 123) }.not_to raise_error
      buffer = described_class.instance_variable_get(:@buffer)
      expect(buffer.last).to include("123")
    end
  end

  describe 'signal handling' do
    it 'cleans up on interrupt signal' do
      handler = nil
      allow(described_class).to receive(:trap).with("INT") { |&block| handler = block }
      allow(described_class).to receive(:trap).with("TERM")
      allow(described_class).to receive(:cleanup)

      described_class.send(:setup_signal_handlers)
      expect(described_class).to receive(:cleanup)
      expect { handler.call }.to raise_error(SystemExit)
    end
  end
end
