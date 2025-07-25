# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Constants::UIConstants do
  it 'defines terminal defaults' do
    expect(described_class::DEFAULT_HEIGHT).to eq(24)
    expect(described_class::DEFAULT_WIDTH).to eq(80)
    expect(described_class::MIN_HEIGHT).to eq(10)
    expect(described_class::MIN_WIDTH).to eq(40)
  end

  it 'defines layout constants' do
    expect(described_class::HEADER_HEIGHT).to eq(2)
    expect(described_class::FOOTER_HEIGHT).to eq(2)
    expect(described_class::SPLIT_VIEW_DIVIDER_WIDTH).to eq(5)
  end

  it 'defines visual indicators' do
    expect(described_class::POINTER_SYMBOL).to eq('▸')
    expect(described_class::DIVIDER_SYMBOL).to eq('│')
  end
end
