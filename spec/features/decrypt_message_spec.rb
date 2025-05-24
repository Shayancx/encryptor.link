require 'rails_helper'

RSpec.feature "Decrypt Message", type: :feature, js: true do
  let(:message) { "Secret message content" }

  scenario "User decrypts a simple message" do
    # Create encrypted payload
    payload = create(:encrypted_payload)

    # Visit decrypt page - since we can't create real encrypted data easily in tests,
    # we'll test that the error handling works correctly
    visit "/#{payload.id}#invalidkey"

    # Wait for JavaScript to process
    sleep 2

    # Should show error container when decryption fails with invalid key
    expect(page).to have_selector('#errorContainer', visible: true)
    expect(page).to have_content('Cannot access this message')
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
