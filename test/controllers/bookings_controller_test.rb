require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
  test "Gast kann nicht buchen" do
    post bookings_path, params: { showtime_id: showtimes(:evening).id, seat_ids: [ seats(:a2).id ] }
    assert_redirected_to login_path
  end

  test "FA-3 Kunde bucht freie Sitzplaetze" do
    sign_in_as users(:customer)

    assert_difference("Booking.count", 2) do
      post bookings_path, params: {
        showtime_id: showtimes(:evening).id,
        seat_ids: [ seats(:a2).id, seats(:b2).id ]
      }
    end

    assert_redirected_to bookings_path
  end

  test "NFA-1 bereits gebuchter Platz wird abgelehnt" do
    sign_in_as users(:other_customer)

    assert_no_difference("Booking.count") do
      post bookings_path, params: { showtime_id: showtimes(:evening).id, seat_ids: [ seats(:a1).id ] }
    end

    assert_redirected_to showtime_path(showtimes(:evening))
    assert_match(/bereits/, flash[:alert])
  end

  test "Buchung ohne Sitzplatzauswahl wird abgewiesen" do
    sign_in_as users(:customer)

    assert_no_difference("Booking.count") do
      post bookings_path, params: { showtime_id: showtimes(:evening).id, seat_ids: [] }
    end

    assert_match(/mindestens einen Sitzplatz/, flash[:alert])
  end

  test "Sitzplatz aus fremdem Saal wird abgelehnt" do
    sign_in_as users(:customer)

    assert_no_difference("Booking.count") do
      post bookings_path, params: { showtime_id: showtimes(:evening).id, seat_ids: [ seats(:other_a1).id ] }
    end
  end

  test "FA-4 Kunde sieht nur eigene Tickets" do
    sign_in_as users(:other_customer)
    get bookings_path

    assert_response :success
    assert_select "h2", count: 0
  end

  test "Kunde darf fremdes Ticket nicht oeffnen" do
    sign_in_as users(:other_customer)
    get booking_path(bookings(:customer_a1))

    assert_response :redirect
  end

  test "Buchung wird im Aktivitaetsprotokoll erfasst" do
    sign_in_as users(:customer)

    assert_difference("ActivityLog.where(action: 'booking_created').count", 1) do
      post bookings_path, params: { showtime_id: showtimes(:evening).id, seat_ids: [ seats(:b2).id ] }
    end
  end

  test "FA-Opt-1 fremd reservierter Platz kann nicht gebucht werden" do
    sign_in_as users(:customer)

    assert_no_difference("Booking.count") do
      post bookings_path, params: { showtime_id: showtimes(:evening).id, seat_ids: [ seats(:b1).id ] }
    end

    assert_redirected_to showtime_path(showtimes(:evening))
    assert_match(/anderen Person gebucht/, flash[:alert])
  end

  test "FA-Opt-1 eigene Reservierung wird bei der Buchung aufgeloest" do
    sign_in_as users(:other_customer)

    assert_difference([ "Booking.count", "-SeatHold.count" ], 1) do
      post bookings_path, params: { showtime_id: showtimes(:evening).id, seat_ids: [ seats(:b1).id ] }
    end

    assert_redirected_to bookings_path
  end

  test "FA-Opt-2 Zahlungsmethode wird auf der Buchung gespeichert" do
    sign_in_as users(:customer)

    post bookings_path, params: {
      showtime_id: showtimes(:evening).id,
      seat_ids: [ seats(:a2).id ],
      payment_method: "twint"
    }

    assert_equal "twint", Booking.last.payment_method
    assert_equal "TWINT", Booking.last.payment_method_label
  end

  test "unbekannte Zahlungsmethode wird verworfen statt gespeichert" do
    sign_in_as users(:customer)

    post bookings_path, params: {
      showtime_id: showtimes(:evening).id,
      seat_ids: [ seats(:a2).id ],
      payment_method: "bitcoin"
    }

    assert_nil Booking.last.payment_method
    assert_redirected_to bookings_path
  end
end
