require "test_helper"

class SeatTest < ActiveSupport::TestCase
  test "Sitznummer ist pro Saal und Reihe eindeutig" do
    duplicate = Seat.new(auditorium: auditoria(:hall_one), row: "A", number: 1)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :number
  end

  test "label kombiniert Reihe und Nummer" do
    assert_equal "A1", seats(:a1).label
  end
end
