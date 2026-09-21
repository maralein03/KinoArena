require "application_system_test_case"

class AdminAreaTest < ApplicationSystemTestCase
  test "NFA-4 Kunde sieht keine Admin-Navigation" do
    sign_in_as users(:customer)

    assert_no_link "Spielplan"
    assert_no_link "Säle"
    assert_no_link "Benutzer"
    assert_no_link "Protokoll"
  end

  test "Admin legt einen Saal samt Saalplan an" do
    sign_in_as users(:admin)

    click_on "Säle"
    click_on "Neuer Saal"

    fill_in "Bezeichnung", with: "Saal 3 – Lounge"
    fill_in "Anzahl Reihen", with: "4"
    fill_in "Plätze pro Reihe", with: "6"
    click_button "Saal anlegen"

    assert_text "24 Sitzplätzen angelegt"
    assert_text "Saal 3 – Lounge"
  end

  test "NFA-4 Kunde wird von der Filmverwaltung abgewiesen" do
    sign_in_as users(:customer)
    visit admin_movies_path

    assert_text "Zugriff verweigert"
    assert_no_text "Filmverwaltung"
  end

  test "FA-5 Admin legt einen Film an" do
    sign_in_as users(:admin)

    click_on "Filme"
    click_on "Neuer Film"

    fill_in "Titel", with: "Systemtest-Film"
    fill_in "Beschreibung", with: "Ein Film, der im Systemtest entsteht."
    fill_in "Dauer (Minuten)", with: "101"
    click_button "Film anlegen"

    assert_text "wurde angelegt"
    assert_text "Systemtest-Film"
  end

  test "FA-6 Admin terminiert eine Vorstellung" do
    sign_in_as users(:admin)

    click_on "Spielplan"
    click_on "Neue Vorstellung"

    select movies(:krimi).title, from: "Film"
    select auditoria(:hall_one).name, from: "Saal"
    fill_in "Beginn", with: 12.days.from_now.change(hour: 18, min: 0).strftime("%Y-%m-%dT%H:%M")
    fill_in "Preis (CHF)", with: "17.50"
    click_button "Vorstellung anlegen"

    assert_text "wurde angelegt"
  end

  test "Aktivitaetsprotokoll zeigt die Anmeldung des Admins" do
    sign_in_as users(:admin)

    click_on "Protokoll"

    assert_text "Aktivitätsprotokoll"
    assert_text "login"
    assert_text users(:admin).email_address
  end
end
