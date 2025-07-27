# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::EPUBDocument, 'edge cases', fake_fs: true do
  let(:epub_path) { '/edge_case.epub' }

  before do
    FileUtils.mkdir_p('/tmp/extracted/META-INF')
    FileUtils.touch(epub_path)
    allow(Dir).to receive(:mktmpdir).and_yield('/tmp/extracted')
    allow(Zip::File).to receive(:open).and_yield(double('zip_file', each: nil))
  end

  it 'handles corrupted container.xml' do
    File.write('/tmp/extracted/META-INF/container.xml', '<invalid xml')
    doc = described_class.new(epub_path)
    expect(doc.chapters.first[:title]).to match(/Error Loading|Empty Book/)
  end

  it 'handles OPF with missing manifest items' do
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
          <dc:title xmlns:dc="http://purl.org/dc/elements/1.1/">Test</dc:title>
        </metadata>
        <manifest></manifest>
        <spine>
          <itemref idref="missing"/>
        </spine>
      </package>
    XML

    doc = described_class.new(epub_path)
    expect(doc.chapters).not_to be_empty
  end

  it 'handles HTML files with BOM' do
    File.write('/tmp/extracted/META-INF/container.xml', <<-XML)
      <container>
        <rootfiles>
          <rootfile full-path="content.opf" />
        </rootfiles>
      </container>
    XML

    File.write('/tmp/extracted/content.opf', <<-XML)
      <package>
        <manifest>
          <item id="ch1" href="ch1.html" />
        </manifest>
        <spine>
          <itemref idref="ch1"/>
        </spine>
      </package>
    XML

    # Write file with BOM - the BOM is stripped by read_file_content
    File.write('/tmp/extracted/ch1.html', "\uFEFF<html><body>Test</body></html>")

    doc = described_class.new(epub_path)
    # The chapter should exist, even if empty due to processing
    expect(doc.chapters).not_to be_empty
  end

  it 'handles missing rootfile in container' do
    File.write('/tmp/extracted/META-INF/container.xml', '<container></container>')
    doc = described_class.new(epub_path)
    # Should have at least one chapter (error or empty)
    expect(doc.chapters).not_to be_empty
    expect(doc.chapters.first[:title]).to match(/Empty Book|Error/)
  end

  it 'handles file read errors in chapters' do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(/ch1\.html/).and_raise(Errno::ENOENT)

    File.write('/tmp/extracted/META-INF/container.xml', <<-XML)
      <container>
        <rootfiles>
          <rootfile full-path="content.opf" />
        </rootfiles>
      </container>
    XML

    File.write('/tmp/extracted/content.opf', <<-XML)
      <package>
        <manifest>
          <item id="ch1" href="ch1.html" />
        </manifest>
        <spine>
          <itemref idref="ch1"/>
        </spine>
      </package>
    XML

    doc = described_class.new(epub_path)
    expect(doc.chapters).not_to be_empty
  end
end
