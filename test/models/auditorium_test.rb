require "test_helper"

class AuditoriumTest < ActiveSupport::TestCase
  test "Name muss eindeutig sein" do
    duplicate = Auditorium.new(name: auditoria(:hall_one).name, total_seats: 10)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :name
  end

  test "hat Sitzplaetze" do
    assert_equal 4, auditoria(:hall_one).seats.count
  end
end
