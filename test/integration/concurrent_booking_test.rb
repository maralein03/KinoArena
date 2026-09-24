require "test_helper"

# NFA-1 unter echten Bedingungen: mehrere Threads mit eigenen Datenbank-
# verbindungen greifen gleichzeitig auf denselben Sitzplatz zu.
# Der Test laeuft deshalb ohne Transaktions-Rollback – sonst waeren die
# Testdaten fuer die anderen Verbindungen unsichtbar.
class ConcurrentBookingTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  CONTENDERS = 5

  setup do
    @movie = Movie.create!(title: "Wettlauf", description: "Testfilm", duration_minutes: 100)
    @auditorium = Auditorium.create!(name: "Wettlauf-Saal #{SecureRandom.hex(4)}",
                                     row_count: 1, seats_per_row: 1)
    @showtime = Showtime.create!(movie: @movie, auditorium: @auditorium,
                                 start_time: 3.days.from_now, price: 20)
    @seat = @auditorium.seats.sole
    @users = Array.new(CONTENDERS) do |i|
      User.create!(name: "Wettlauf #{i}", email_address: "wettlauf#{i}-#{SecureRandom.hex(4)}@example.test",
                   password: "passwort123")
    end
  end

  teardown do
    Booking.where(showtime: @showtime).delete_all
    @showtime.destroy
    @auditorium.destroy
    @movie.destroy
    User.where(id: @users.map(&:id)).delete_all
  end

  test "nur ein Thread erhaelt den letzten freien Platz" do
    start_gate = Concurrent::CountDownLatch.new(1)
    results = Queue.new

    threads = @users.map do |user|
      Thread.new do
        start_gate.wait(5)
        ActiveRecord::Base.connection_pool.with_connection do
          Booking.create!(user: user, showtime: @showtime, seat: @seat)
          results << :booked
        end
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        results << :rejected
      end
    end

    start_gate.count_down
    threads.each(&:join)

    outcomes = Array.new(results.size) { results.pop }

    assert_equal 1, outcomes.count(:booked), "Der Sitzplatz darf nur einmal vergeben werden"
    assert_equal CONTENDERS - 1, outcomes.count(:rejected)
    assert_equal 1, Booking.where(showtime: @showtime, seat: @seat).count
  end
end
