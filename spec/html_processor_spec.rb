# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Helpers::HTMLProcessor do
  describe '.extract_title' do
    it 'extracts title from title tag' do
      html = '<html><head><title>My Title</title></head></html>'
      expect(described_class.extract_title(html)).to eq('My Title')
    end

    it 'extracts title from h1 tag when no title tag' do
      html = '<html><body><h1>Chapter Title</h1></body></html>'
      expect(described_class.extract_title(html)).to eq('Chapter Title')
    end

    it 'returns nil when no title found' do
      html = '<html><body><p>No title here</p></body></html>'
      expect(described_class.extract_title(html)).to be_nil
    end

    it 'decodes HTML entities' do
      html = '<title>Title &amp; More</title>'
      expect(described_class.extract_title(html)).to eq('Title & More')
    end
  end

  describe '.html_to_text' do
    it 'converts HTML to plain text' do
      html = '<p>Hello</p><p>World</p>'
      text = described_class.html_to_text(html)
      # The actual implementation adds double newlines after </p>
      expect(text.strip).to match(/Hello\s+World/)
    end

    it 'removes script and style tags' do
      html = '<script>alert("hi")</script><style>body{}</style><p>Text</p>'
      text = described_class.html_to_text(html)
      expect(text.strip).to eq('Text')
    end

    it 'converts br tags to newlines' do
      html = 'Line 1<br>Line 2<br/>Line 3'
      text = described_class.html_to_text(html)
      expect(text).to include("Line 1\nLine 2\nLine 3")
    end

    it 'handles nested tags' do
      html = '<div><p>Text with <strong>bold</strong> and <em>italic</em></p></div>'
      text = described_class.html_to_text(html)
      expect(text).to include('Text with bold and italic')
    end

    it 'decodes basic HTML entities' do
      html = '<p>Quote: &quot;Hello&quot; &amp; goodbye</p>'
      text = described_class.html_to_text(html)
      expect(text).to include('"Hello" & goodbye')
    end
  end
end
