# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::EPUBDocument, 'comprehensive', fake_fs: true do
  let(:epub_path) { '/comprehensive.epub' }

  before do
    FileUtils.mkdir_p('/tmp/extracted/META-INF')
    FileUtils.touch(epub_path)
    allow(Dir).to receive(:mktmpdir).and_yield('/tmp/extracted')
  end

  describe 'error recovery' do
    it 'creates error chapter on any exception during parsing' do
      allow(Zip::File).to receive(:open).and_raise(StandardError.new('Generic error'))
      doc = described_class.new(epub_path)
      expect(doc.chapters.first[:title]).to eq('Error Loading')
      # The error chapter should contain the original exception message. Join
      # the lines to make the expectation independent of formatting.
      expect(doc.chapters.first[:lines].join("\n")).to include('Generic error')
    end

    it 'ensures at least one chapter exists even with empty spine' do
      allow(Zip::File).to receive(:open).and_yield(double('zip_file', each: nil))

      File.write('/tmp/extracted/META-INF/container.xml', <<-XML)
        <container>
          <rootfiles>
            <rootfile full-path="content.opf" />
          </rootfiles>
        </container>
      XML

      File.write('/tmp/extracted/content.opf', <<-XML)
        <package>
          <metadata></metadata>
          <manifest></manifest>
          <spine></spine>
        </package>
      XML

      doc = described_class.new(epub_path)
      expect(doc.chapters).not_to be_empty
      expect(doc.chapters.first[:title]).to match(/Empty Book/)
    end
  end

  describe 'metadata extraction' do
    it 'handles missing title gracefully' do
      allow(Zip::File).to receive(:open).and_yield(double('zip_file', each: nil))

      File.write('/tmp/extracted/META-INF/container.xml', <<-XML)
        <container>
          <rootfiles>
            <rootfile full-path="content.opf" />
          </rootfiles>
        </container>
      XML

      File.write('/tmp/extracted/content.opf', <<-XML)
        <package>
          <metadata>
            <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">fr</dc:language>
          </metadata>
          <manifest></manifest>
          <spine></spine>
        </package>
      XML

      doc = described_class.new(epub_path)
      expect(doc.title).to eq('comprehensive') # Falls back to filename
      expect(doc.language).to eq('fr_FR')
    end
  end
end
