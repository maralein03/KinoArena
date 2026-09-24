require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  test "Reset-Mail enthaelt Empfaenger und Link" do
    user = users(:customer)
    token = user.generate_token_for(:password_reset)
    mail = UserMailer.password_reset(user, token)

    assert_equal [ user.email_address ], mail.to
    assert_match(/Passwort/, mail.subject)
    assert_includes mail.text_part.decoded, edit_password_reset_url(token, host: "example.com")
  end
end
