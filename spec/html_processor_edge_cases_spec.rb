# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EbookReader::Helpers::HTMLProcessor do
  describe ".html_to_text" do
    it "handles malformed HTML" do
      html = "<p>Unclosed paragraph"
      text = described_class.html_to_text(html)
      expect(text).to include("Unclosed paragraph")
    end

    it "handles empty HTML" do
      expect(described_class.html_to_text("")).to eq("")
    end

    it "handles HTML with only whitespace" do
      html = "   \n\t   "
      expect(described_class.html_to_text(html).strip).to eq("")
    end

    it "handles deeply nested structures" do
      html = "<div><div><div><p>Deep text</p></div></div></div>"
      text = described_class.html_to_text(html)
      expect(text).to include("Deep text")
    end

    it "cleans up excessive newlines" do
      html = "<p>Para1</p>\n\n\n\n<p>Para2</p>"
      text = described_class.html_to_text(html)
      # Should not have more than 2 newlines in a row
      expect(text).not_to match(/\n{4,}/)
    end
  end

  describe ".clean_html" do
    it "handles various HTML entities" do
      text = described_class.clean_html("&lt;tag&gt; &amp; &quot;quote&quot;")
      expect(text).to eq('<tag> & "quote"')
    end
  end
end
