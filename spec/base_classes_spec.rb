# frozen_string_literal: true

require 'spec_helper'


RSpec.describe EbookReader::ReaderModes::BaseMode do
  let(:reader) { double('reader', config: :conf) }

  before do
    stub_const('DummyMode', Class.new(described_class))
  end

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
