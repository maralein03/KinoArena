require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "Anmeldung mit korrekten Daten" do
    sign_in_as users(:customer)

    assert_redirected_to root_path
    follow_redirect!
    assert_select "nav", text: /#{users(:customer).name}/
  end

  test "Anmeldung mit falschem Passwort schlaegt fehl" do
    post login_path, params: { email_address: users(:customer).email_address, password: "falsch" }

    assert_response :unprocessable_entity
    assert_match(/falsch/, response.body)
  end

  test "fehlgeschlagener Anmeldeversuch wird protokolliert" do
    assert_difference("ActivityLog.where(action: 'login_failed').count", 1) do
      post login_path, params: { email_address: users(:customer).email_address, password: "falsch" }
    end
  end

  test "Abmeldung beendet die Sitzung" do
    sign_in_as users(:customer)
    delete logout_path

    assert_redirected_to root_path
    get users_url
    assert_redirected_to login_path
  end
end
