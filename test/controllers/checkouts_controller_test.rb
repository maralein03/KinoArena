require "test_helper"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
  test "Gast wird zur Anmeldung geschickt" do
    get showtime_checkout_path(showtimes(:evening), seat_ids: [ seats(:a2).id ])

    assert_redirected_to login_path
  end

  test "FA-Opt-2 Checkout zeigt Zusammenfassung und Zahlungsmethoden" do
    sign_in_as users(:customer)

    get showtime_checkout_path(showtimes(:evening), seat_ids: [ seats(:a2).id, seats(:b2).id ])

    assert_response :success
    assert_select "h1", text: "Buchung bestätigen"
    assert_select "input[name=payment_method][value=apple_pay]"
    assert_select "input[name=payment_method][value=credit_card]"
    assert_select "input[name=payment_method][value=twint]"
  end

  test "Checkout ohne Sitzplatzauswahl fuehrt zurueck zum Saalplan" do
    sign_in_as users(:customer)

    get showtime_checkout_path(showtimes(:evening))

    assert_redirected_to showtime_path(showtimes(:evening))
    assert_match(/mindestens einen Sitzplatz/, flash[:alert])
  end

  test "Gesamtbetrag entspricht Preis mal Anzahl Plaetze" do
    sign_in_as users(:customer)

    get showtime_checkout_path(showtimes(:evening), seat_ids: [ seats(:a2).id, seats(:b2).id ])

    assert_select "dd", text: "CHF 37.00"
  end
end
