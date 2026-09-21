require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "FA-1 Registrierung erstellt ein Kundenkonto" do
    visit signup_path

    fill_in "Name", with: "Neue Kundin"
    fill_in "E-Mail", with: "neue.kundin@example.test"
    fill_in "Passwort", with: "passwort123"
    fill_in "Passwort wiederholen", with: "passwort123"
    click_button "Konto erstellen"

    assert_text "Willkommen bei KinoArena"
    assert_text "Neue Kundin"
  end

  test "NFA-5 fehlerhafte Registrierung behaelt Eingaben und zeigt Fehler" do
    visit signup_path

    fill_in "Name", with: "Unvollständig"
    fill_in "E-Mail", with: "keine-email"
    fill_in "Passwort", with: "kurz"
    fill_in "Passwort wiederholen", with: "kurz"
    click_button "Konto erstellen"

    assert_text "Bitte korrigiere folgende Angaben"
    assert_field "Name", with: "Unvollständig"
    assert_field "E-Mail", with: "keine-email"
  end

  test "Anmeldung mit falschem Passwort zeigt eine Fehlermeldung" do
    visit login_path

    fill_in "E-Mail", with: users(:customer).email_address
    fill_in "Passwort", with: "falschesPasswort"
    click_button "Anmelden"

    assert_text "E-Mail-Adresse oder Passwort ist falsch"
  end

  test "Abmeldung beendet die Sitzung" do
    sign_in_as users(:customer)
    assert_text users(:customer).name

    click_button "Abmelden"

    assert_text "Du wurdest abgemeldet"
    assert_link "Anmelden"
  end
end
