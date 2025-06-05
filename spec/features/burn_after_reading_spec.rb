require 'rails_helper'

RSpec.feature "Burn After Reading", type: :feature, js: true do
  scenario "User creates burn after reading message" do
    visit root_path

    find('#richEditor').set('Self-destruct message')
    check 'burnToggle'

    expect(find('#viewsSelect')).to be_disabled
    expect(page).to have_content('Views setting will be ignored')

    click_button 'Encrypt & Generate Link'

    expect(page).to have_content('Your encrypted link has been generated')
  end
end
