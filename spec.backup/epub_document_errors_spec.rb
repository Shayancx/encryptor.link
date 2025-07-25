# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::EPUBDocument, "error handling", fake_fs: true do
  let(:epub_path) { '/books/test.epub' }

  before do
    FileUtils.mkdir_p('/books')
    FileUtils.touch(epub_path)
    allow(Dir).to receive(:mktmpdir).and_yield('/tmp/extracted')
  end

  it 'handles Zip::Error during extraction' do
    allow(Zip::File).to receive(:open).and_raise(Zip::Error)
    doc = described_class.new(epub_path)
    expect(doc.chapters.first[:title]).to eq('Error Loading')
  end

  it 'handles missing container.xml' do
    allow(Zip::File).to receive(:open).and_yield(double('zip_file', each: nil))
    allow(File).to receive(:exist?).with(File.join('/tmp/extracted', 'META-INF', 'container.xml')).and_return(false)
    doc = described_class.new(epub_path)
    expect(doc.chapters.first[:title]).to eq("Empty Book")
  end

  it 'handles missing OPF file' do
    container_xml_path = File.join('/tmp/extracted', 'META-INF', 'container.xml')
    allow(Zip::File).to receive(:open).and_yield(double('zip_file', each: nil))
    allow(File).to receive(:exist?).with(container_xml_path).and_return(true)
    xml = '<container><rootfiles><rootfile full-path="content.opf"/></rootfiles></container>'
    allow(File).to receive(:read).with(container_xml_path).and_return(xml)
    allow(File).to receive(:exist?).with(File.join('/tmp/extracted', 'content.opf')).and_return(false)
    doc = described_class.new(epub_path)
    expect(doc.chapters.first[:title]).to eq("Empty Book")
  end
end
