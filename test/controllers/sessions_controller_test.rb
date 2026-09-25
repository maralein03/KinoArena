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

  test "NFA-7 zu viele Fehlversuche sperren die Anmeldung voruebergehend" do
    user = users(:other_customer)

    SessionsController::MAX_FAILED_ATTEMPTS.times do
      post login_path, params: { email_address: user.email_address, password: "falsch" }
      assert_response :unprocessable_entity
    end

    assert_difference("ActivityLog.where(action: 'login_blocked').count", 1) do
      post login_path, params: { email_address: user.email_address, password: "passwort123" }
    end
    assert_response :too_many_requests

    travel (SessionsController::LOCKOUT_PERIOD + 1.minute) do
      sign_in_as user
      assert_redirected_to root_path
    end
  end

  test "NFA-7 erfolgreiche Anmeldung setzt den Fehlerzaehler zurueck" do
    user = users(:admin)

    post login_path, params: { email_address: user.email_address, password: "falsch" }
    sign_in_as user
    assert_redirected_to root_path

    delete logout_path
    sign_in_as user
    assert_redirected_to root_path
  end
end
