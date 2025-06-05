require 'rails_helper'

RSpec.feature "Encrypt Message Fixed", type: :feature, js: true do
  scenario "User encrypts files without errors" do
    visit root_path

    # Use a fixture file
    file_path = Rails.root.join('spec', 'fixtures', 'test.txt')

    # Ensure file exists
    unless File.exist?(file_path)
      File.write(file_path, "Test file content\n")
    end

    # Make file input visible and attach file
    execute_script("document.getElementById('fileInput').style.display = 'block';")
    attach_file('fileInput', file_path)

    expect(page).to have_content('test.txt')

    # Add a message to ensure we're not sending empty content
    find('#richEditor').set('Test message with file')

    click_button 'Encrypt & Generate Link'

    # Wait for either success or handle the alert
    begin
      expect(page).to have_content('Your encrypted link has been generated', wait: 5)
    rescue Capybara::ElementNotFound
      # If there's an alert, dismiss it and check what went wrong
      if alert_text
        dismiss_alert
        fail "Encryption failed with alert: #{alert_text}"
      end
    end
  end
end
