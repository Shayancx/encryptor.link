# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EmailService do
  describe '.send_password_reset_email' do
    let(:email) { 'test@example.com' }
    let(:reset_token) { SecureRandom.hex(32) }

    context 'when email is enabled' do
      before do
        allow(Environment).to receive(:email_enabled?).and_return(true)
        allow(Environment).to receive(:smtp_config).and_return({
                                                                 host: 'localhost',
                                                                 port: 1025,
                                                                 from: 'noreply@encryptor.link'
                                                               })
      end

      it 'sends email successfully' do
        mail_double = double('mail')
        allow(Mail).to receive(:new).and_return(mail_double)
        allow(mail_double).to receive(:delivery_method)
        allow(mail_double).to receive(:deliver!)

        result = EmailService.send_password_reset_email(email, reset_token)
        expect(result).to be true
      end
    end

    context 'when email is disabled' do
      before do
        allow(Environment).to receive(:email_enabled?).and_return(false)
      end

      it 'returns false' do
        result = EmailService.send_password_reset_email(email, reset_token)
        expect(result).to be false
      end
    end
  end

  describe '.send_welcome_email' do
    let(:email) { 'test@example.com' }

    context 'when email is enabled' do
      before do
        allow(Environment).to receive(:email_enabled?).and_return(true)
        allow(Environment).to receive(:smtp_config).and_return({
                                                                 host: 'localhost',
                                                                 port: 1025,
                                                                 from: 'noreply@encryptor.link'
                                                               })
      end

      it 'sends welcome email' do
        mail_double = double('mail')
        allow(Mail).to receive(:new).and_return(mail_double)
        allow(mail_double).to receive(:delivery_method)
        allow(mail_double).to receive(:deliver!)

        result = EmailService.send_welcome_email(email)
        expect(result).to be true
      end
    end
  end
end
