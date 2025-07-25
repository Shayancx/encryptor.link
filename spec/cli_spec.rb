require 'spec_helper'

RSpec.describe EbookReader::CLI do
  let(:main_menu) { instance_double(EbookReader::MainMenu) }

  before do
    allow(EbookReader::MainMenu).to receive(:new).and_return(main_menu)
    allow(main_menu).to receive(:run)
  end

  describe ".run" do
    it "creates and runs a main menu" do
      expect(EbookReader::MainMenu).to receive(:new).and_return(main_menu)
      expect(main_menu).to receive(:run)
      
      described_class.run
    end
  end
end
