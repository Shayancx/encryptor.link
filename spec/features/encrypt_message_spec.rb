require 'rails_helper'

RSpec.feature "Encrypt Message", type: :feature, js: true do
  scenario "User encrypts a simple message" do
    visit root_path

    # Enter message
    find('#richEditor').set('This is a secret message')

    # Set options
    select '1 day', from: 'ttlSelect'
    select '1 view', from: 'viewsSelect'

    # Submit form
    click_button 'Encrypt & Generate Link'

    # Check result
    expect(page).to have_content('Your encrypted link has been generated')
    link_value = find('#encryptedLink').value

    # More flexible regex that handles the actual URL format
    expect(link_value).to match(%r{^http://[^/]+/[a-f0-9-]+#[\w+/=-]+$})
  end

  scenario "User encrypts message with password" do
    visit root_path

    find('#richEditor').set('Password protected secret')

    # Enable password protection
    check 'passwordToggle'
    fill_in 'passwordInput', with: 'mySecretPass123'

    click_button 'Encrypt & Generate Link'

    expect(page).to have_content('This link requires a password')
  end

  scenario "User encrypts files" do
    visit root_path

    # Attach file
    file_path = Rails.root.join('spec', 'fixtures', 'test.txt')
    File.write(file_path, 'Test file content')

    attach_file('fileInput', file_path, make_visible: true)

    expect(page).to have_content('test.txt')

    click_button 'Encrypt & Generate Link'

    expect(page).to have_content('Your encrypted link has been generated')

    File.delete(file_path)
  end

  scenario "Validation errors are shown" do
    visit root_path

    # Try to submit without message or files
    click_button 'Encrypt & Generate Link'

    expect(page.driver.browser.switch_to.alert.text).to include('Please enter a message or select at least one file')
    page.driver.browser.switch_to.alert.accept
  end
end
