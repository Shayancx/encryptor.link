# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/helpers/opf_processor'

describe EbookReader::Helpers::OpfProcessor, fake_fs: true do
  let(:opf_content) do
    <<-OPF
      <package>
        <manifest>
          <item id="item1" href="chapter1.html" media-type="application/xhtml+xml" />
          <item id="item2" href="chapter2.html" media-type="application/xhtml+xml" />
          <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />
        </manifest>
        <spine toc="ncx">
          <itemref idref="item1" />
          <itemref idref="item2" />
        </spine>
      </package>
    OPF
  end

  let(:opf_path) { '/test.opf' }

  before do
    File.write(opf_path, opf_content)
  end

  describe ".new" do
    it "parses the spine and manifest" do
      processor = described_class.new(opf_path)
      expect(processor.spine).to eq(['chapter1.html', 'chapter2.html'])
      expect(processor.manifest).to eq({
        'item1' => 'chapter1.html',
        'item2' => 'chapter2.html',
        'ncx' => 'toc.ncx'
      })
    end

    it "handles a missing opf file" do
      expect { described_class.new('/nonexistent.opf') }.to raise_error(Errno::ENOENT)
    end

    it "handles an empty opf file" do
      File.write('/empty.opf', '')
      processor = described_class.new('/empty.opf')
      expect(processor.spine).to be_empty
      expect(processor.manifest).to be_empty
    end
  end
end
