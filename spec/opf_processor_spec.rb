# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Helpers::OPFProcessor, fake_fs: true do
  let(:opf_content) do
    <<-XML
      <package xmlns="http://www.idpf.org/2007/opf">
        <metadata>
          <dc:title xmlns:dc="http://purl.org/dc/elements/1.1/">Test Book</dc:title>
          <dc:language xmlns:dc="http://purl.org/dc/elements/1.1/">en</dc:language>
        </metadata>
        <manifest>
          <item id="ch1" href="chapter1.html" media-type="application/xhtml+xml"/>
          <item id="ch2" href="chapter2.html" media-type="application/xhtml+xml"/>
          <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
        </manifest>
        <spine toc="ncx">
          <itemref idref="ch1"/>
          <itemref idref="ch2"/>
        </spine>
      </package>
    XML
  end

  let(:ncx_content) do
    <<-XML
      <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/">
        <navMap>
          <navPoint>
            <navLabel><text>Chapter 1 Title</text></navLabel>
            <content src="chapter1.html"/>
          </navPoint>
          <navPoint>
            <navLabel><text>Chapter 2 Title</text></navLabel>
            <content src="chapter2.html"/>
          </navPoint>
        </navMap>
      </ncx>
    XML
  end

  before do
    File.write('/book/content.opf', opf_content)
    File.write('/book/toc.ncx', ncx_content)
  end

  let(:processor) { described_class.new('/book/content.opf') }

  describe "#extract_metadata" do
    it "extracts title and language" do
      metadata = processor.extract_metadata
      expect(metadata[:title]).to eq("Test Book")
      expect(metadata[:language]).to eq("en_EN")
    end

    it "handles missing metadata" do
      File.write('/empty.opf', '<package/>')
      processor = described_class.new('/empty.opf')

      metadata = processor.extract_metadata
      expect(metadata).to eq({})
    end
  end

  describe "#build_manifest_map" do
    it "builds manifest id to href map" do
      manifest = processor.build_manifest_map
      expect(manifest).to eq({
                               'ch1' => 'chapter1.html',
                               'ch2' => 'chapter2.html',
                               'ncx' => 'toc.ncx'
                             })
    end
  end

  describe "#extract_chapter_titles" do
    it "extracts titles from NCX file" do
      manifest = processor.build_manifest_map
      titles = processor.extract_chapter_titles(manifest)

      expect(titles).to eq({
                             'chapter1.html' => 'Chapter 1 Title',
                             'chapter2.html' => 'Chapter 2 Title'
                           })
    end

    it "handles missing NCX file" do
      FileUtils.rm('/book/toc.ncx')
      manifest = processor.build_manifest_map
      titles = processor.extract_chapter_titles(manifest)

      expect(titles).to eq({})
    end
  end

  describe "#process_spine" do
    it "yields chapter information in order" do
      manifest = processor.build_manifest_map
      titles = processor.extract_chapter_titles(manifest)
      chapters = []

      processor.process_spine(manifest, titles) do |path, num, title|
        chapters << { path: path, num: num, title: title }
      end

      expect(chapters.size).to eq(2)
      expect(chapters[0][:num]).to eq(1)
      expect(chapters[0][:title]).to eq('Chapter 1 Title')
    end
  end
end
