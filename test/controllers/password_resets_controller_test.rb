require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:customer)
    ActionMailer::Base.deliveries.clear
  end

  test "Formular ist oeffentlich erreichbar" do
    get new_password_reset_path
    assert_response :success
  end

  test "Anfrage verschickt einen Link und protokolliert sie" do
    assert_difference("ActivityLog.where(action: 'password_reset_requested').count", 1) do
      post password_resets_path, params: { email_address: @user.email_address.upcase }
    end

    assert_redirected_to login_path
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [ @user.email_address ], ActionMailer::Base.deliveries.last.to
    assert @user.reload.password_reset_sent_at.present?
  end

  test "unbekannte Adresse liefert dieselbe Meldung ohne Mail" do
    post password_resets_path, params: { email_address: "gibtesnicht@example.test" }

    assert_redirected_to login_path
    assert_empty ActionMailer::Base.deliveries
    assert_match(/Falls ein Konto/, flash[:notice])
  end

  test "zweite Anfrage innerhalb der Sperrfrist verschickt keine Mail" do
    post password_resets_path, params: { email_address: @user.email_address }
    post password_resets_path, params: { email_address: @user.email_address }

    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "gueltiger Token oeffnet das Formular" do
    get edit_password_reset_path(@user.generate_token_for(:password_reset))
    assert_response :success
  end

  test "neues Passwort wird gesetzt und der Token verfaellt" do
    token = @user.generate_token_for(:password_reset)

    patch password_reset_path(token),
          params: { user: { password: "neuespasswort", password_confirmation: "neuespasswort" } }

    assert_redirected_to login_path
    assert @user.reload.authenticate("neuespasswort")
    assert_nil @user.password_reset_sent_at

    # Der Token haengt am Passwort-Hash und ist nach der Aenderung wertlos.
    get edit_password_reset_path(token)
    assert_redirected_to new_password_reset_path
  end

  test "abgelaufener Token wird abgewiesen und protokolliert" do
    token = @user.generate_token_for(:password_reset)

    travel (User::PASSWORD_RESET_VALIDITY + 1.minute) do
      assert_difference("ActivityLog.where(action: 'password_reset_invalid_token').count", 1) do
        get edit_password_reset_path(token)
      end
      assert_redirected_to new_password_reset_path
    end
  end

  test "zu kurzes Passwort zeigt das Formular erneut" do
    patch password_reset_path(@user.generate_token_for(:password_reset)),
          params: { user: { password: "kurz", password_confirmation: "kurz" } }

    assert_response :unprocessable_entity
    assert_not @user.reload.authenticate("kurz")
  end

  test "leeres Passwort wird nicht stillschweigend akzeptiert" do
    patch password_reset_path(@user.generate_token_for(:password_reset)),
          params: { user: { password: "", password_confirmation: "" } }

    assert_response :unprocessable_entity
    assert @user.reload.authenticate("passwort123")
  end

  test "angemeldete Benutzer werden weggeleitet" do
    sign_in_as @user
    get new_password_reset_path
    assert_redirected_to root_path
  end
end
