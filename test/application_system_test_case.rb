require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # rack_test laeuft ohne installierten Browser; SYSTEM_TEST_DRIVER=selenium aktiviert Headless Chrome.
  if ENV["SYSTEM_TEST_DRIVER"] == "selenium"
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  else
    driven_by :rack_test
  end

  def sign_in_as(user, password: "passwort123")
    visit login_path
    fill_in "E-Mail", with: user.email_address
    fill_in "Passwort", with: password
    click_button "Anmelden"
  end

  private

  # turbo-rails wartet nach jedem visit auf verbundene Cable-Streams; ohne JS-Treiber gibt es die nie.
  def connect_turbo_cable_stream_sources
    super unless page.driver.is_a?(Capybara::RackTest::Driver)
  end
end
