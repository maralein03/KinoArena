# Idempotente Beispieldaten fuer KinoArena.
# Ausfuehren mit: bin/rails db:seed

admin = User.find_or_initialize_by(email_address: "admin@kinoarena.ch")
admin.assign_attributes(name: "Mara Spichiger", admin: true)
admin.password = "adminadmin" if admin.new_record?
admin.save!

customer = User.find_or_initialize_by(email_address: "kunde@example.com")
customer.assign_attributes(name: "Test Kunde", admin: false)
customer.password = "kundekunde" if customer.new_record?
customer.save!

movies = [
  { title: "Dune: Part Three", description: "Paul Atreides kehrt auf Arrakis zurueck.", duration_minutes: 165 },
  { title: "Die Ostschweizer Nacht", description: "Ein Schweizer Kriminalfilm in St. Gallen.", duration_minutes: 112 },
  { title: "Nebula Run", description: "Science-Fiction-Abenteuer am Rand der Galaxie.", duration_minutes: 128 }
].map do |attrs|
  movie = Movie.find_or_initialize_by(title: attrs[:title])
  movie.update!(attrs)
  movie
end

auditoria = [
  { name: "Saal 1", rows: ("A".."E").to_a, seats_per_row: 10 },
  { name: "Saal 2", rows: ("A".."C").to_a, seats_per_row: 8 }
].map do |config|
  auditorium = Auditorium.find_or_initialize_by(name: config[:name])
  auditorium.total_seats = config[:rows].size * config[:seats_per_row]
  auditorium.save!

  config[:rows].each do |row|
    (1..config[:seats_per_row]).each do |number|
      Seat.find_or_create_by!(auditorium: auditorium, row: row, number: number)
    end
  end

  auditorium
end

start = Time.current.beginning_of_hour + 1.day
[
  [ movies[0], auditoria[0], start + 19.hours, 18.50 ],
  [ movies[1], auditoria[1], start + 20.hours, 15.00 ],
  [ movies[2], auditoria[0], start + 1.day + 19.hours, 16.50 ]
].each do |movie, auditorium, start_time, price|
  showtime = Showtime.find_or_initialize_by(movie: movie, auditorium: auditorium, start_time: start_time)
  showtime.price = price
  showtime.save!
end

puts "Seed abgeschlossen: #{User.count} Benutzer, #{Movie.count} Filme, " \
     "#{Auditorium.count} Saele, #{Seat.count} Sitze, #{Showtime.count} Vorstellungen."
