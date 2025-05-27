require 'rails_helper'

RSpec.feature "Encrypt Message", type: :feature, js: true do
  before do
    # Ensure we're on the encryption page
    visit root_path
    # Wait for page to fully load
    expect(page).to have_css('#encryptForm', wait: 5)
  end

  scenario "User encrypts a simple message" do
    # Enter message using JavaScript to ensure it's properly set
    page.execute_script("document.getElementById('richEditor').innerHTML = 'This is a secret message'")
    page.execute_script("document.getElementById('hidden_message').value = 'This is a secret message'")

    # Set options
    select '1 day', from: 'ttlSelect'
    select '1 view', from: 'viewsSelect'

    # Submit form
    click_button 'Encrypt & Generate Link'

    # Wait for result
    expect(page).to have_content('Your encrypted link has been generated', wait: 10)

    # Check link format
    link_value = find('#encryptedLink', visible: false).value
    expect(link_value).to match(%r{^https?://[^/]+/[a-f0-9-]+#[\w+/=-]+$})
  end

  scenario "User encrypts message with password" do
    # Enter message
    page.execute_script("document.getElementById('richEditor').innerHTML = 'Password protected secret'")
    page.execute_script("document.getElementById('hidden_message').value = 'Password protected secret'")

    # Enable password protection
    check 'passwordToggle'

    # Wait for password field to appear
    expect(page).to have_field('passwordInput', wait: 5)

    fill_in 'passwordInput', with: 'mySecretPass123'

    click_button 'Encrypt & Generate Link'

    expect(page).to have_content('This link requires a password', wait: 10)
  end

  scenario "User encrypts files" do
    # Create a test file
    file_path = Rails.root.join('spec', 'fixtures', 'test.txt')

    # Attach file
    attach_file('fileInput', file_path, visible: false)

    # Wait for file to appear
    expect(page).to have_content('test.txt', wait: 5)

    click_button 'Encrypt & Generate Link'

    expect(page).to have_content('Your encrypted link has been generated', wait: 10)
  end

  scenario "Validation errors prevent submission" do
    # Try to submit without message or files
    click_button 'Encrypt & Generate Link'

    # Wait for error handling
    sleep 1

    # Check if form is still visible (wasn't submitted)
    expect(page).to have_button('Encrypt & Generate Link')
    expect(page).not_to have_content('Your encrypted link has been generated')
  end
end
