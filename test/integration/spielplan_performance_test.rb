require "test_helper"

# NFA-3: Die Ladezeit des Spielplans haengt an der Anzahl der Datenbankabfragen.
# Dieser Test haelt fest, dass sie nicht mit der Anzahl der Filme waechst (kein N+1).
class SpielplanPerformanceTest < ActionDispatch::IntegrationTest
  test "Spielplan braucht unabhaengig von der Anzahl Filme gleich viele Abfragen" do
    baseline = count_queries { get root_path }
    assert_response :success

    10.times { |index| create_showtime(index) }

    erweitert = count_queries { get root_path }
    assert_response :success

    assert_equal baseline, erweitert,
                 "Der Spielplan erzeugt zusätzliche Abfragen pro Film (N+1-Problem)."
  end

  test "Spielplan kommt mit wenigen Abfragen aus" do
    5.times { |index| create_showtime(index) }

    queries = count_queries { get root_path }

    assert_operator queries, :<=, 10, "Der Spielplan sollte mit wenigen Abfragen auskommen."
  end

  private

  def count_queries
    count = 0
    counter = ->(_name, _start, _finish, _id, payload) do
      count += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ])
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end

  def create_showtime(index)
    movie = Movie.create!(title: "Lasttest-Film #{index}", description: "Beschreibung", duration_minutes: 90)
    Showtime.create!(movie: movie,
                     auditorium: auditoria(:hall_one),
                     start_time: (index + 10).days.from_now.change(hour: 20, min: 0),
                     price: 15)
  end
end
