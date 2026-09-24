require "test_helper"

class AuditoriumTest < ActiveSupport::TestCase
  test "Name muss eindeutig sein" do
    duplicate = Auditorium.new(name: auditoria(:hall_one).name, row_count: 2, seats_per_row: 5)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :name
  end

  test "hat Sitzplaetze" do
    assert_equal 4, auditoria(:hall_one).seats.count
  end

  test "Sitzplaetze werden beim Anlegen automatisch erzeugt" do
    auditorium = Auditorium.create!(name: "Generierter Saal", row_count: 3, seats_per_row: 5)

    assert_equal 15, auditorium.seats.count
    assert_equal 15, auditorium.total_seats
    assert_equal %w[A B C], auditorium.rows
    assert_equal (1..5).to_a, auditorium.seats.where(row: "A").order(:number).pluck(:number)
  end

  test "Reihen- und Platzangaben sind beim Anlegen Pflicht" do
    auditorium = Auditorium.new(name: "Ohne Plan")

    assert_not auditorium.valid?
    assert_includes auditorium.errors.attribute_names, :row_count
    assert_includes auditorium.errors.attribute_names, :seats_per_row
  end

  test "mehr Reihen als Buchstaben sind nicht erlaubt" do
    auditorium = Auditorium.new(name: "Zu gross", row_count: 27, seats_per_row: 5)

    assert_not auditorium.valid?
    assert_includes auditorium.errors.attribute_names, :row_count
  end

  test "booked_seat_count zaehlt gebuchte Plaetze" do
    assert_equal 1, auditoria(:hall_one).booked_seat_count
  end
end
