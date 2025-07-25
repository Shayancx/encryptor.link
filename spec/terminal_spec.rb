require 'spec_helper'

RSpec.describe EbookReader::Terminal do
  describe ".size" do
    it "returns terminal dimensions" do
      allow(IO.console).to receive(:winsize).and_return([30, 100])
      expect(described_class.size).to eq([30, 100])
    end

    it "returns default size on error" do
      allow(IO.console).to receive(:winsize).and_raise(StandardError)
      expect(described_class.size).to eq([24, 80])
    end
  end

  describe ".clear" do
    it "prints clear screen sequence" do
      expect($stdout).to receive(:flush)
      expect(described_class).to receive(:print).with("\e[2J\e[H")
      described_class.clear
    end
  end

  describe ".write" do
    it "adds text to buffer with position" do
      described_class.start_frame
      described_class.write(10, 20, "Hello")
      buffer = described_class.instance_variable_get(:@buffer)
      expect(buffer).to include("\e[10;20HHello")
    end
  end

  describe ".setup" do
    it "sets up terminal for raw mode" do
      expect($stdout).to receive(:sync=).with(true)
      expect(described_class).to receive(:print)
      expect(described_class).to receive(:clear)
      described_class.setup
    end
  end

  describe ".cleanup" do
    it "restores terminal state" do
      expect($stdout).to receive(:flush)
      expect(described_class).to receive(:print)
      described_class.cleanup
    end
  end

  describe ".read_key" do
    it "reads single character" do
      allow(IO.console).to receive(:raw).and_yield
      allow($stdin).to receive(:read_nonblock).and_return("a")
      expect(described_class.read_key).to eq("a")
    end

    it "handles escape sequences" do
      allow(IO.console).to receive(:raw).and_yield
      allow($stdin).to receive(:read_nonblock).and_return("\e", "[A")
      expect(described_class.read_key).to eq("\e[A")
    end

    it "returns nil when no input available" do
      allow(IO.console).to receive(:raw).and_yield
      allow($stdin).to receive(:read_nonblock).and_raise(IO::WaitReadable)
      expect(described_class.read_key).to be_nil
    end
  end
end

RSpec.describe EbookReader::Terminal::ANSI do
  describe "color constants" do
    it "defines color codes" do
      expect(described_class::RESET).to eq("\e[0m")
      expect(described_class::RED).to eq("\e[31m")
      expect(described_class::GREEN).to eq("\e[32m")
      expect(described_class::BLUE).to eq("\e[34m")
    end
  end

  describe ".move" do
    it "returns cursor move sequence" do
      expect(described_class.move(5, 10)).to eq("\e[5;10H")
    end
  end

  describe ".clear_line" do
    it "returns clear line sequence" do
      expect(described_class.clear_line).to eq("\e[2K")
    end
  end
end
