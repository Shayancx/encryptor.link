# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Comprehensive Validation' do
  describe EbookReader::Validators::FilePathValidator do
    let(:validator) { described_class.new }

    it 'validates all conditions properly' do
      # Mock all file checks
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:readable?).and_return(true)
      allow(File).to receive(:size).and_return(1000)

      expect(validator.validate('/valid.epub')).to be true
      expect(validator.errors).to be_empty
    end

    it 'collects multiple errors' do
      allow(File).to receive(:exist?).and_return(false)

      expect(validator.validate('/missing.txt')).to be false
      expect(validator.errors.map { |e| e[:field] }).to include(:path)
    end

    it 'validates empty files' do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:readable?).and_return(true)
      allow(File).to receive(:size).and_return(0)

      expect(validator.validate('/empty.epub')).to be false
      expect(validator.errors.last[:message]).to include('empty')
    end
  end

  describe EbookReader::Validators::TerminalSizeValidator do
    let(:validator) { described_class.new }

    it 'provides recommendations' do
      recommendations = validator.recommendations(60, 20)

      expect(recommendations[:current]).to eq({ width: 60, height: 20 })
      expect(recommendations[:minimum]).to eq({
                                                width: EbookReader::Constants::UIConstants::MIN_WIDTH,
                                                height: EbookReader::Constants::UIConstants::MIN_HEIGHT,
                                              })
      expect(recommendations[:needs_resize]).to be true
    end

    it 'validates recommended size' do
      expect(validator.recommended_size?(80, 24)).to be true
      expect(validator.recommended_size?(40, 10)).to be false
    end
  end
end
