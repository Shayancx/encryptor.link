require 'rails_helper'

RSpec.feature "Decrypt Message", type: :feature, js: true do
  let(:message) { "Secret message content" }
  let(:key) { SecureRandom.random_bytes(32) }
  let(:iv) { SecureRandom.random_bytes(12) }

  before do
    # Mock encryption for predictable results
    allow(SecureRandom).to receive(:random_bytes).with(32).and_return(key)
    allow(SecureRandom).to receive(:random_bytes).with(12).and_return(iv)
  end

  scenario "User decrypts a simple message" do
    # Create encrypted payload
    payload = create(:encrypted_payload)

    # Visit decrypt page with key in fragment
    visit "/#{payload.id}##{Base64.urlsafe_encode64(key, padding: false)}"

    # Should see decrypted content
    expect(page).to have_content('One-time message!')
    expect(page).to have_button('Copy Message')
  end

  scenario "User decrypts password-protected message" do
    payload = create(:encrypted_payload, :with_password)

    visit "/#{payload.id}"

    expect(page).to have_content('Password Protected Content')

    fill_in 'passwordInput', with: 'wrongpassword'
    click_button 'Decrypt'

    expect(page).to have_content('Incorrect password')
  end

  scenario "Expired message shows error" do
    payload = create(:encrypted_payload, :expired)

    visit "/#{payload.id}#test"

    expect(page).to have_content('Cannot access this message')
    expect(page).to have_content('expired')
  end

  scenario "Message with no views left shows error" do
    payload = create(:encrypted_payload, :no_views_left)

    visit "/#{payload.id}#test"

    expect(page).to have_content('Cannot access this message')
  end
end
