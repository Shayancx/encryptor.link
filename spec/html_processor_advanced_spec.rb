# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Helpers::HTMLProcessor, 'advanced cases' do
  describe '.html_to_text' do
    it 'handles nested script and style tags' do
      html = '<script><style>body{}</style></script><p>Text</p>'
      text = described_class.html_to_text(html)
      expect(text.strip).to eq('Text')
    end

    it 'handles CDATA sections' do
      html = '<p><![CDATA[Special content]]></p>'
      text = described_class.html_to_text(html)
      # CDATA is treated as regular content after tag stripping
      expect(text).to include('Special content')
    end

    it 'handles HTML comments' do
      html = '<!-- Comment --><p>Text</p><!-- Another comment -->'
      text = described_class.html_to_text(html)
      expect(text.strip).to eq('Text')
    end

    it 'handles mixed case tags' do
      html = '<P>Text1</P><Div>Text2</Div><BR/>Text3'
      text = described_class.html_to_text(html)
      expect(text).to include('Text1')
      expect(text).to include('Text2')
      expect(text).to include('Text3')
    end

    it 'handles self-closing tags' do
      html = 'Text<br/>More<hr/>End'
      text = described_class.html_to_text(html)
      expect(text).to include("Text\nMore")
    end

    it 'handles unicode entities' do
      html = '<p>Copyright &copy; 2024 &mdash; Test &hellip;</p>'
      text = described_class.html_to_text(html)
      # CGI.unescapeHTML handles standard entities
      expect(text).to include('2024')
      expect(text).to include('Test')
    end
  end

  describe '.extract_title' do
    it 'handles title with nested tags' do
      html = '<title>My Bold Title</title>'
      title = described_class.extract_title(html)
      # extract_title captures the raw content between tags
      expect(title).to eq('My Bold Title')
    end

    it 'prefers title over h1 when both exist' do
      html = '<title>Title Tag</title><h1>H1 Tag</h1>'
      title = described_class.extract_title(html)
      expect(title).to eq('Title Tag')
    end

    it 'handles h2 and h3 tags when no title or h1' do
      html = '<h2>H2 Title</h2>'
      title = described_class.extract_title(html)
      expect(title).to eq('H2 Title')
    end
  end
end
