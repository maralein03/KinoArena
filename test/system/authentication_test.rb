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

  test "FA-1 vergessenes Passwort kann ueber den Link neu gesetzt werden" do
    user = users(:customer)
    ActionMailer::Base.deliveries.clear

    visit login_path
    click_link "Passwort vergessen?"
    fill_in "E-Mail", with: user.email_address
    click_button "Link anfordern"

    assert_text "Falls ein Konto zu dieser E-Mail-Adresse existiert"

    link = ActionMailer::Base.deliveries.last.text_part.decoded[%r{https?://\S+/edit}]
    visit URI.parse(link).request_uri

    fill_in "Neues Passwort", with: "brandneues123"
    fill_in "Passwort wiederholen", with: "brandneues123"
    click_button "Passwort speichern"

    assert_text "Passwort wurde geaendert"

    fill_in "E-Mail", with: user.email_address
    fill_in "Passwort", with: "brandneues123"
    click_button "Anmelden"

    assert_text user.name
  end
end
