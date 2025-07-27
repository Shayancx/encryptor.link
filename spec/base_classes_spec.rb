# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Renderers::BaseRenderer do
  let(:config) { double('config') }
  subject(:renderer) { described_class.new(config) }

  before { allow(EbookReader::Terminal).to receive(:write) }

  it 'stores config' do
    expect(renderer.config).to eq(config)
  end

  it 'writes to terminal' do
    renderer.send(:write, 1, 1, 'hi')
    expect(EbookReader::Terminal).to have_received(:write).with(1, 1, 'hi')
  end

  it 'wraps text with color' do
    result = renderer.send(:with_color, EbookReader::Terminal::ANSI::RED, 'x')
    expect(result).to eq("\e[31mx\e[0m")
  end
end

RSpec.describe EbookReader::ReaderModes::BaseMode do
  let(:reader) { double('reader', config: :conf) }

  class DummyMode < described_class; end

  subject(:mode) { DummyMode.new(reader) }

  it 'returns config from reader' do
    expect(mode.send(:config)).to eq(:conf)
  end

  it 'raises NotImplementedError for draw' do
    expect { mode.draw(1, 1) }.to raise_error(NotImplementedError)
  end

  it 'raises NotImplementedError for handle_input' do
    expect { mode.handle_input('x') }.to raise_error(NotImplementedError)
  end
end
