require "test_helper"

class SeatHoldsControllerTest < ActionDispatch::IntegrationTest
  test "Gast kann keinen Platz reservieren" do
    post showtime_seat_holds_path(showtimes(:evening)), params: { seat_id: seats(:a2).id }

    assert_redirected_to login_path
  end

  test "FA-Opt-1 Kunde reserviert einen freien Platz fuer 5 Minuten" do
    sign_in_as users(:customer)

    assert_difference("SeatHold.count", 1) do
      post showtime_seat_holds_path(showtimes(:evening)), params: { seat_id: seats(:a2).id }
    end

    assert_response :success
    body = response.parsed_body
    assert body["expires_at"].present?
    assert_in_delta SeatHold::HOLD_DURATION.to_i, body["remaining_seconds"], 5
  end

  test "fremd reservierter Platz wird mit 409 abgelehnt" do
    sign_in_as users(:customer)

    assert_no_difference("SeatHold.count") do
      post showtime_seat_holds_path(showtimes(:evening)), params: { seat_id: seats(:b1).id }
    end

    assert_response :conflict
    assert_match(/jemand anderem reserviert/, response.parsed_body["error"])
  end

  test "bereits gebuchter Platz kann nicht reserviert werden" do
    sign_in_as users(:customer)

    post showtime_seat_holds_path(showtimes(:evening)), params: { seat_id: seats(:a1).id }

    assert_response :unprocessable_entity
  end

  test "eigene Reservierung kann wieder freigegeben werden" do
    sign_in_as users(:other_customer)

    assert_difference("SeatHold.count", -1) do
      delete showtime_seat_hold_path(showtimes(:evening), seats(:b1))
    end

    assert_response :no_content
  end

  test "fremde Reservierung kann nicht freigegeben werden" do
    sign_in_as users(:customer)

    assert_no_difference("SeatHold.count") do
      delete showtime_seat_hold_path(showtimes(:evening), seats(:b1))
    end

    assert_response :not_found
  end

  test "abgelaufene Reservierungen werden beim Zugriff aufgeraeumt" do
    seat_holds(:one).update_column(:expires_at, 1.minute.ago)
    sign_in_as users(:customer)

    post showtime_seat_holds_path(showtimes(:evening)), params: { seat_id: seats(:b1).id }

    assert_response :success
    assert_equal users(:customer).id, SeatHold.find_by(seat_id: seats(:b1).id).user_id
  end
end
