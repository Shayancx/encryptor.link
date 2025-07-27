# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::EPUBDocument, fake_fs: true do
  let(:epub_path) { '/test.epub' }
  let(:document) { described_class.new(epub_path) }

  before do
    # Instead of creating actual zip files, let's mock the behavior
    # Create the extracted structure that EPUBDocument expects
    FileUtils.mkdir_p('/tmp/extracted/META-INF')

    # Create container.xml
    File.write('/tmp/extracted/META-INF/container.xml', <<-XML)
      <container>
        <rootfiles>
          <rootfile full-path="content.opf" />
        </rootfiles>
      </container>
    XML

    # Create content.opf
    File.write('/tmp/extracted/content.opf', <<-XML)
      <package>
        <metadata>
          <dc:title xmlns:dc="http://purl.org/dc/elements/1.1/">Test Book</dc:title>
          <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
        </metadata>
        <manifest>
          <item id="ch1" href="ch1.html" media-type="application/xhtml+xml"/>
        </manifest>
        <spine>
          <itemref idref="ch1"/>
        </spine>
      </package>
    XML

    # Create chapter HTML
    File.write('/tmp/extracted/ch1.html', <<-HTML)
      <html>
        <head><title>Chapter 1</title></head>
        <body>
          <h1>Chapter 1</h1>
          <p>This is the content of chapter 1.</p>
        </body>
      </html>
    HTML

    # Mock Dir.mktmpdir to return our prepared directory
    allow(Dir).to receive(:mktmpdir).and_yield('/tmp/extracted')

    # Create a simple zip file for the EPUB (just a marker file)
    File.write(epub_path, 'FAKE_ZIP_FILE')

    # Mock Zip::File if it's loaded
    if defined?(Zip)
      allow(Zip::File).to receive(:open).with(epub_path).and_yield(
        double('zip_file').tap do |zip|
          allow(zip).to receive(:each) do |&block|
            # Simulate entries
            [
              double('entry', name: 'META-INF/container.xml',
                              extract: nil,
                              directory?: false),
              double('entry', name: 'content.opf',
                              extract: nil,
                              directory?: false),
              double('entry', name: 'ch1.html',
                              extract: nil,
                              directory?: false),
            ].each(&block)
          end
        end
      )
    end
  end

  describe '#initialize' do
    it 'loads epub and extracts title' do
      expect(document.title).to eq('Test Book')
    end

    it 'extracts chapters' do
      expect(document.chapter_count).to eq(1)
      expect(document.chapters.first.title).to eq('Chapter 1')
    end

    it 'handles corrupted epub' do
      # For corrupted EPUB, the error handling creates an error chapter
      allow(Dir).to receive(:mktmpdir).and_raise(StandardError.new('Invalid zip'))

      doc = described_class.new('/bad.epub')
      expect(doc.chapter_count).to eq(1)
      expect(doc.chapters.first.title).to eq('Error Loading')
    end
  end

  describe '#get_chapter' do
    it 'returns chapter by index' do
      chapter = document.get_chapter(0)
      expect(chapter).to be_a(EbookReader::Models::Chapter)
      expect(chapter.title).to eq('Chapter 1')
      expect(chapter.lines).to include('This is the content of chapter 1.')
    end

    it 'returns nil for invalid index' do
      expect(document.get_chapter(-1)).to be_nil
      expect(document.get_chapter(10)).to be_nil
    end
  end
end
