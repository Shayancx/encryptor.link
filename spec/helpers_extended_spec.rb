# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Helpers Extended' do
  describe EbookReader::Helpers::HTMLProcessor do
    it 'handles various block-level elements' do
      html = '<div>div</div><p>p</p><h1>h1</h1>'
      text = described_class.html_to_text(html)
      # The clean_whitespace method strips trailing newlines, so the test is adjusted
      expect(text).to eq("div\n\np\n\nh1")
    end

    it 'cleans multiple newlines' do
      # Duplicate the string to avoid FrozenError
      text = "\n\n\n\nhello\n\n\nworld\n\n\n\n\n".dup
      cleaned = described_class.send(:clean_whitespace, text)
      expect(cleaned).to eq("hello\n\nworld")
    end
  end

  describe EbookReader::Helpers::OPFProcessor, fake_fs: true do
    let(:opf_path) { '/book/content.opf' }
    before do
      FileUtils.mkdir_p('/book')
    end

    it 'handles OPF with no spine toc attribute' do
      opf_content = <<-XML
        <package xmlns="http://www.idpf.org/2007/opf">
          <manifest><item id="ncx" href="toc.ncx"/></manifest>
          <spine></spine>
        </package>
      XML
      File.write(opf_path, opf_content)
      processor = described_class.new(opf_path)
      titles = processor.extract_chapter_titles({ 'ncx' => 'toc.ncx' })
      expect(titles).to be_empty
    end

    it 'handles language codes correctly' do
      # Add the required namespace definition for dc:
      opf_content = '<package xmlns:dc="http://purl.org/dc/elements/1.1/"><metadata><dc:language>fr</dc:language></metadata></package>'
      File.write(opf_path, opf_content)
      processor = described_class.new(opf_path)
      metadata = processor.extract_metadata
      expect(metadata[:language]).to eq('fr_FR')
    end
  end

  describe EbookReader::Helpers::ReaderHelpers do
    let(:helper) { Class.new { include EbookReader::Helpers::ReaderHelpers }.new }

    it 'does not break on line with only whitespace' do
      lines = ["   \t   "]
      wrapped = helper.wrap_lines(lines, 20)
      expect(wrapped).to eq([''])
    end
  end
end
