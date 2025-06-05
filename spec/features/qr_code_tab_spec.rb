require 'rails_helper'

RSpec.feature "QR Code Tab", type: :feature, js: true do
  scenario "User can view QR code after generation" do
    visit root_path

    # Enter a message and enable QR code generation
    find('#richEditor').set('QR code test message')
    check 'qrToggle'

    click_button 'Encrypt & Generate Link'

    expect(page).to have_content('Your encrypted link has been generated')

    # Click on QR Code tab
    find('#qr-tab').click

    # QR panel should be visible and tab should be active
    expect(page).to have_css('#qr-panel.active, #qr-panel.show', visible: true)
    expect(page).to have_css('#qr-tab.active')
    expect(page).to have_button('Download QR Code')
  end
end
