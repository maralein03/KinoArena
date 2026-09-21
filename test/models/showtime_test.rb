require "test_helper"

class ShowtimeTest < ActiveSupport::TestCase
  test "freie Sitzplaetze schliessen gebuchte Plaetze aus" do
    showtime = showtimes(:evening)

    assert_not_includes showtime.available_seats, seats(:a1)
    assert_includes showtime.available_seats, seats(:a2)
  end

  test "Startzeit darf beim Anlegen nicht in der Vergangenheit liegen" do
    showtime = Showtime.new(movie: movies(:dune), auditorium: auditoria(:hall_two),
                            start_time: 1.day.ago, price: 10)

    assert_not showtime.valid?
    assert_includes showtime.errors.attribute_names, :start_time
  end

  test "NFA-2 Optimistic Locking meldet veraltete Daten" do
    showtime = showtimes(:evening)
    stale_copy = Showtime.find(showtime.id)

    showtime.update!(price: 21.0)

    assert_raises(ActiveRecord::StaleObjectError) { stale_copy.update!(price: 22.0) }
  end
end
