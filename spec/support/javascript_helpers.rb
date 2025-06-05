module JavaScriptHelpers
  def dismiss_alert
    page.driver.browser.switch_to.alert.accept
  rescue Selenium::WebDriver::Error::NoSuchAlertError
    # Alert already dismissed
  end

  def alert_text
    page.driver.browser.switch_to.alert.text
  rescue Selenium::WebDriver::Error::NoSuchAlertError
    nil
  end
end

RSpec.configure do |config|
  config.include JavaScriptHelpers, type: :feature
end
