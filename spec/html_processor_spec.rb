# frozen_string_literal: true
require 'spec_helper'
require_relative '../lib/ebook_reader/helpers/html_processor'

describe EbookReader::Helpers::HtmlProcessor do
  describe ".process" do
    let(:html) do
      <<-HTML
        <html>
          <head>
            <title>Test</title>
          </head>
          <body>
            <h1>Header</h1>
            <p>This is a paragraph with <strong>strong</strong> text.</p>
            <p>Another paragraph.</p>
            <br>
            <a href="http://example.com">Link</a>
          </body>
        </html>
      HTML
    end

    it "extracts text from HTML" do
      processed_text = EbookReader::Helpers::HtmlProcessor.process(html)
      expected_text = "Header\nThis is a paragraph with strong text.\nAnother paragraph.\n\nLink"
      expect(processed_text).to eq(expected_text)
    end

    it "handles empty html" do
      processed_text = EbookReader::Helpers::HtmlProcessor.process("")
      expect(processed_text).to eq("")
    end

    it "handles html with no body" do
      html = "<html><head><title>Test</title></head></html>"
      processed_text = EbookReader::Helpers::HtmlProcessor.process(html)
      expect(processed_text).to eq("")
    end
  end
end
