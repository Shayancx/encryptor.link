require 'spec_helper'

RSpec.describe "Navigation Commands" do
  let(:reader) { instance_double(EbookReader::Reader) }
  let(:doc) { instance_double(EbookReader::EPUBDocument, chapter_count: 2) }
  
  before do
    allow(reader).to receive(:instance_variable_get).with(:@doc).and_return(doc)
    allow(reader).to receive(:instance_variable_get).with(:@current_chapter).and_return(0)
    allow(reader).to receive(:instance_variable_get).with(:@max_page).and_return(10)
    allow(EbookReader::Terminal).to receive(:size).and_return([24, 80])
    allow(reader).to receive(:send)
  end
  
  describe EbookReader::Commands::ScrollDownCommand do
    let(:command) { described_class.new(reader) }
    
    it 'calls scroll_down on receiver' do
      expect(reader).to receive(:send).with(:scroll_down)
      command.execute
    end
  end
  
  describe EbookReader::Commands::ScrollUpCommand do
    let(:command) { described_class.new(reader) }
    
    it 'calls scroll_up on receiver' do
      expect(reader).to receive(:send).with(:scroll_up)
      command.execute
    end
  end
  
  describe EbookReader::Commands::NextPageCommand do
    let(:command) { described_class.new(reader) }
    
    it 'calculates layout and calls next_page' do
      expect(reader).to receive(:send).with(:get_layout_metrics, 80, 24).and_return([40, 20])
      expect(reader).to receive(:send).with(:adjust_for_line_spacing, 20).and_return(18)
      expect(reader).to receive(:send).with(:next_page, 18, 10)
      command.execute
    end
  end
  
  describe EbookReader::Commands::NextChapterCommand do
    let(:command) { described_class.new(reader) }
    
    it 'calls next_chapter when not at last chapter' do
      expect(reader).to receive(:send).with(:next_chapter)
      command.execute
    end
    
    it 'does not call next_chapter when at last chapter' do
      allow(reader).to receive(:instance_variable_get).with(:@current_chapter).and_return(1)
      expect(reader).not_to receive(:send).with(:next_chapter)
      command.execute
    end
  end
  
  describe EbookReader::Commands::GoToStartCommand do
    let(:command) { described_class.new(reader) }
    
    it 'resets pages' do
      expect(reader).to receive(:send).with(:reset_pages)
      command.execute
    end
  end
  
  describe EbookReader::Commands::GoToEndCommand do
    let(:command) { described_class.new(reader) }
    
    it 'goes to end with calculated metrics' do
      expect(reader).to receive(:send).with(:get_layout_metrics, 80, 24).and_return([40, 20])
      expect(reader).to receive(:send).with(:adjust_for_line_spacing, 20).and_return(18)
      expect(reader).to receive(:send).with(:go_to_end, 18, 10)
      command.execute
    end
  end
end
