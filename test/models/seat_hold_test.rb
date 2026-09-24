require "test_helper"

class SeatHoldTest < ActiveSupport::TestCase
  test "Reservierung laeuft nach 5 Minuten ab" do
    hold = SeatHold.create!(showtime: showtimes(:evening), seat: seats(:a2), user: users(:customer))

    assert_in_delta SeatHold::HOLD_DURATION.to_i, hold.remaining_seconds, 2
  end

  test "ein Platz kann pro Vorstellung nur einmal reserviert werden" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      SeatHold.create!(showtime: showtimes(:evening), seat: seats(:b1), user: users(:customer))
    end
  end

  test "bereits gebuchte Plaetze koennen nicht reserviert werden" do
    hold = SeatHold.new(showtime: showtimes(:evening), seat: seats(:a1), user: users(:customer))

    assert_not hold.valid?
    assert_includes hold.errors.attribute_names, :seat
  end

  test "active liefert nur laufende Reservierungen" do
    abgelaufen = SeatHold.create!(showtime: showtimes(:evening), seat: seats(:a2), user: users(:customer))
    abgelaufen.update_column(:expires_at, 1.minute.ago)

    assert_includes SeatHold.active, seat_holds(:one)
    assert_not_includes SeatHold.active, abgelaufen
  end

  test "release_expired! gibt abgelaufene Plaetze frei" do
    abgelaufen = SeatHold.create!(showtime: showtimes(:evening), seat: seats(:a2), user: users(:customer))
    abgelaufen.update_column(:expires_at, 1.minute.ago)

    assert_difference("SeatHold.count", -1) { SeatHold.release_expired! }
    assert SeatHold.exists?(seat_holds(:one).id)
  end

  test "held_by? erkennt die eigene Reservierung" do
    assert seat_holds(:one).held_by?(users(:other_customer))
    assert_not seat_holds(:one).held_by?(users(:customer))
    assert_not seat_holds(:one).held_by?(nil)
  end
end
