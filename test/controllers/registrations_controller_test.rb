require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "Registrierungsformular ist erreichbar" do
    get signup_path
    assert_response :success
  end

  test "neue Registrierung erstellt einen Kunden" do
    assert_difference("User.count", 1) do
      post signup_path, params: { user: {
        name: "Neuer Kunde",
        email_address: "neu@example.test",
        password: "passwort123",
        password_confirmation: "passwort123"
      } }
    end

    assert_redirected_to root_path
    assert_not User.find_by(email_address: "neu@example.test").admin?
  end

  test "Registrierung als Admin ist nicht moeglich" do
    post signup_path, params: { user: {
      name: "Angreifer",
      email_address: "angreifer@example.test",
      password: "passwort123",
      password_confirmation: "passwort123",
      admin: true
    } }

    assert_not User.find_by(email_address: "angreifer@example.test").admin?
  end

  test "NFA-5 fehlerhafte Eingaben zeigen Fehlermeldungen" do
    assert_no_difference("User.count") do
      post signup_path, params: { user: {
        name: "",
        email_address: "keine-email",
        password: "123",
        password_confirmation: "123"
      } }
    end

    assert_response :unprocessable_entity
  end
end
