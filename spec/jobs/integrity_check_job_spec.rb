require 'rails_helper'

RSpec.describe IntegrityCheckJob, type: :job do
  describe '#perform' do
    it 'detects corrupted records and sends security alert' do
      payload = create(:encrypted_payload)
      file = create(:encrypted_file, encrypted_payload: payload)

      payload.update_column(:ciphertext, 'bad')
      file.update_column(:file_data, 'bad')

      called = nil
      original = SecurityAlertService.method(:send_alert)
      SecurityAlertService.singleton_class.class_eval do
        public :send_alert
        define_method(:send_alert) { |**args| called = args }
      end

      begin
        expect { described_class.new.perform }.not_to raise_error
        expect(called[:severity]).to eq('critical')
        expect(called[:title]).to eq('Data Integrity Check Failed')
      ensure
        SecurityAlertService.singleton_class.send(:define_method, :send_alert, original)
        SecurityAlertService.singleton_class.send(:private, :send_alert)
      end
    end
  end
end
