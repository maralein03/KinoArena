require "application_system_test_case"

class BookingFlowTest < ApplicationSystemTestCase
  test "Kunde bucht vom Programm bis zum Ticket" do
    sign_in_as users(:customer)

    visit root_path
    assert_text "Was läuft"

    click_on movies(:dune).title
    assert_text "Handlung"

    click_on showtimes(:evening).start_time.strftime("%H:%M")
    assert_text "Leinwand"

    check "seat_#{seats(:a2).id}"
    check "seat_#{seats(:b2).id}"
    click_button "submit-booking"

    # FA-Opt-2: Bestaetigung und Zahlungsauswahl
    assert_text "Buchung bestätigen"
    assert_text "2 Tickets"
    assert_text "Zahlungsmethode"

    choose "TWINT"
    click_button "mit Apple Pay bezahlen"

    assert_text "Zahlung erfolgreich"
    assert_text "3 Buchungen"
  end

  test "Gast sieht den Saalplan, kann aber nicht buchen" do
    visit showtime_path(showtimes(:evening))

    assert_text "um Tickets zu buchen"
    assert_selector "#submit-booking[disabled]"
  end

  test "NFA-1 belegter Sitzplatz ist nicht auswaehlbar" do
    sign_in_as users(:customer)
    visit showtime_path(showtimes(:evening))

    assert_no_selector "#seat_#{seats(:a1).id}"
    assert_selector "#seat_#{seats(:a2).id}", visible: :all
  end

  test "Kunde ruft sein Ticket mit QR-Code auf" do
    sign_in_as users(:customer)

    visit bookings_path
    click_on "QR-Code anzeigen", match: :first

    assert_text "Bestätigt"
    assert_text "an der Kinokasse vorzeigen"
    assert_selector "svg[aria-label='QR-Code des Tickets']", visible: :all
  end

  test "Kunde storniert ein Ticket" do
    sign_in_as users(:customer)
    visit bookings_path

    assert_difference("Booking.count", -1) do
      click_button "Stornieren", match: :first
    end

    assert_text "Ticket wurde storniert"
  end
end
