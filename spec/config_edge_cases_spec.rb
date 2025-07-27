# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Config, 'edge cases', fake_fs: true do
  let(:config_file) { described_class::CONFIG_FILE }

  it 'handles config file with extra unknown keys' do
    FileUtils.mkdir_p(described_class::CONFIG_DIR)
    config_data = {
      view_mode: 'split',
      unknown_key: 'value',
      another_unknown: 123,
    }
    File.write(config_file, JSON.pretty_generate(config_data))

    config = described_class.new
    expect(config.view_mode).to eq(:split)
  end

  it 'handles config file with wrong value types' do
    FileUtils.mkdir_p(described_class::CONFIG_DIR)
    config_data = {
      view_mode: 123,
      show_page_numbers: 'yes',
      line_spacing: true,
    }
    File.write(config_file, JSON.pretty_generate(config_data))

    config = described_class.new
    # Should use defaults for invalid values
    expect(config.view_mode).to eq(:split)
  end

  it 'handles readonly filesystem when saving' do
    config = described_class.new
    allow(File).to receive(:write).and_raise(Errno::EROFS)

    expect { config.save }.not_to raise_error
  end

  it 'handles disk full error when saving' do
    config = described_class.new
    allow(File).to receive(:write).and_raise(Errno::ENOSPC)

    expect { config.save }.not_to raise_error
  end
end
