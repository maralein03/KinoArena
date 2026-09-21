require "test_helper"

class BookingTest < ActiveSupport::TestCase
  test "Buchung erhaelt Token und Preis automatisch" do
    booking = Booking.create!(user: users(:customer), showtime: showtimes(:evening), seat: seats(:a2))

    assert booking.qr_code_token.present?
    assert_equal showtimes(:evening).price, booking.total_price
  end

  test "derselbe Sitzplatz kann pro Vorstellung nur einmal gebucht werden" do
    duplicate = Booking.new(user: users(:other_customer), showtime: showtimes(:evening), seat: seats(:a1))

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :seat_id
  end

  test "NFA-1 Unique-Index verhindert Doppelbuchung auf Datenbankebene" do
    duplicate = Booking.new(user: users(:other_customer), showtime: showtimes(:evening), seat: seats(:a1),
                            qr_code_token: SecureRandom.uuid, total_price: 18.5)

    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "Sitzplatz muss zum Saal der Vorstellung gehoeren" do
    booking = Booking.new(user: users(:customer), showtime: showtimes(:evening), seat: seats(:other_a1))

    assert_not booking.valid?
    assert_includes booking.errors.attribute_names, :seat
  end
end
