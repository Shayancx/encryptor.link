# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Integration Edge Cases" do
  describe "ReaderHelpers wrap_lines" do
    let(:helper) { Class.new { include EbookReader::Helpers::ReaderHelpers }.new }

    it 'handles very long words that exceed width' do
      lines = ["supercalifragilisticexpialidocious"]
      wrapped = helper.wrap_lines(lines, 10)
      expect(wrapped).to eq(["supercalifragilisticexpialidocious"])
    end

    it 'handles lines with multiple spaces' do
      lines = ["word1     word2     word3"]
      wrapped = helper.wrap_lines(lines, 15)
      expect(wrapped.join(" ")).to include("word1")
      expect(wrapped.join(" ")).to include("word2")
      expect(wrapped.join(" ")).to include("word3")
    end

    it 'handles tabs and other whitespace' do
      lines = ["word1\tword2\nword3"]
      wrapped = helper.wrap_lines(lines, 20)
      expect(wrapped).not_to be_empty
    end
  end

  describe "Reader display calculations" do
    let(:reader) do
      config = EbookReader::Config.new
      doc = instance_double(EbookReader::EPUBDocument,
                            title: "Test",
                            language: "en",
                            chapter_count: 1,
                            chapters: [EbookReader::Models::Chapter.new(number: '1', title: 'Ch1', lines: ['Line'], metadata: nil)])
      allow(EbookReader::EPUBDocument).to receive(:new).and_return(doc)
      allow(doc).to receive(:get_chapter).and_return(doc.chapters.first)
      allow(EbookReader::BookmarkManager).to receive(:get).and_return([])
      allow(EbookReader::ProgressManager).to receive(:load).and_return(nil)

      EbookReader::Reader.new('/test.epub', config)
    end

    it 'handles terminal resize during reading' do
      allow(EbookReader::Terminal).to receive(:size).and_return([24, 80], [30, 100])

      reader.send(:update_page_map, 80, 24)
      reader.instance_variable_get(:@page_map).dup

      reader.send(:update_page_map, 100, 30)
      reader.instance_variable_get(:@page_map)

      # Page map should be recalculated
      expect(reader.instance_variable_get(:@last_width)).to eq(100)
      expect(reader.instance_variable_get(:@last_height)).to eq(30)
    end
  end

  describe "OPFProcessor namespace handling", fake_fs: true do
    it 'handles OPF files with various namespaces' do
      FileUtils.mkdir_p('book')
      opf_content = <<-XML
        <package xmlns="http://www.idpf.org/2007/opf"#{' '}
                 xmlns:dc="http://purl.org/dc/elements/1.1/"
                 xmlns:opf="http://www.idpf.org/2007/opf">
          <metadata>
            <dc:title>Test</dc:title>
            <dc:creator opf:role="aut">Author</dc:creator>
          </metadata>
        </package>
      XML
      File.write('book/content.opf', opf_content)

      processor = EbookReader::Helpers::OPFProcessor.new('book/content.opf')
      metadata = processor.extract_metadata

      expect(metadata[:title]).to eq("Test")
    end
  end
end
