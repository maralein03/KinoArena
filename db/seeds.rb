# Idempotente Beispieldaten fuer KinoArena.
# Ausfuehren mit: bin/rails db:seed

admin = User.find_or_initialize_by(email_address: "admin@kinoarena.test")
admin.assign_attributes(name: "Mara Spichiger", admin: true)
admin.password = "password123" if admin.new_record?
admin.save!

# Zwei Kunden, um die Doppelbuchungssperre (NFA-1) live vorzufuehren.
[
  { email_address: "anna@example.com", name: "Anna Kundin", password: "annaanna" },
  { email_address: "ben@example.com",  name: "Ben Kunde",   password: "benbenben" }
].each do |attrs|
  customer = User.find_or_initialize_by(email_address: attrs[:email_address])
  customer.assign_attributes(name: attrs[:name], admin: false)
  customer.password = attrs[:password] if customer.new_record?
  customer.save!
end

# Sammelkonto fuer die vorbelegten Plaetze, damit die Demo-Kunden leere Ticketlisten haben.
box_office = User.find_or_initialize_by(email_address: "abendkasse@kinoarena.test")
box_office.assign_attributes(name: "Abendkasse", admin: false)
box_office.password = SecureRandom.hex(16) if box_office.new_record?
box_office.save!

movies = [
  {
    title: "Blade Runner 2099",
    description: "In den neonhellen Megastädten des Jahres 2099 muss ein neuer Blade Runner die " \
                 "verschwimmende Grenze zwischen Mensch und Maschine ergründen, während ein " \
                 "abtrünniges KI-Kollektiv die Zivilisation bedroht.",
    duration_minutes: 142,
    poster_url: "https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=600&q=80"
  },
  {
    title: "Die Ostschweizer Nacht",
    description: "Ein Schweizer Kriminalfilm: Eine Kommissarin jagt in den Gassen von St. Gallen " \
                 "einen Täter, der immer einen Schritt voraus zu sein scheint.",
    duration_minutes: 112,
    poster_url: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600&q=80"
  },
  {
    title: "Nebula Run",
    description: "Ein Schmugglerschiff nimmt am gefährlichsten Rennen der Galaxie teil – " \
                 "quer durch einen kollabierenden Nebel.",
    duration_minutes: 128,
    poster_url: "https://images.unsplash.com/photo-1446776877081-d282a0f896e2?w=600&q=80"
  },
  {
    title: "Papiermond",
    description: "Eine handgezeichnete Animation über ein Mädchen, das jede Nacht in eine " \
                 "Welt aus Papier reist, um ihren verlorenen Bruder zu suchen.",
    duration_minutes: 96,
    poster_url: "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=600&q=80"
  },
  {
    title: "Hollywood 1949",
    description: "Ein Historiendrama über die Traumfabrik der Nachkriegszeit und den Preis des Ruhms.",
    duration_minutes: 134,
    poster_url: "https://images.unsplash.com/photo-1533106418989-88406c7cc8ca?w=600&q=80"
  }
].map do |attrs|
  movie = Movie.find_or_initialize_by(title: attrs[:title])
  movie.update!(attrs)
  movie
end

auditoria = [
  { name: "Saal 1 – Grand", row_count: 10, seats_per_row: 14 },
  { name: "Saal 2 – Studio", row_count: 6, seats_per_row: 10 }
].map do |config|
  auditorium = Auditorium.find_or_initialize_by(name: config[:name])
  # Sitzplaetze werden nur beim erstmaligen Anlegen erzeugt.
  auditorium.assign_attributes(config.except(:name)) if auditorium.new_record?
  auditorium.save!
  auditorium
end

today = Time.zone.now.beginning_of_day
showtimes = [
  [ movies[0], auditoria[0], today + 18.hours,          14.50 ],
  [ movies[0], auditoria[0], today + 21.hours + 15.minutes, 14.50 ],
  [ movies[1], auditoria[1], today + 19.hours + 30.minutes, 16.00 ],
  [ movies[2], auditoria[1], today + 1.day + 20.hours, 16.50 ],
  [ movies[3], auditoria[0], today + 1.day + 15.hours, 12.00 ],
  [ movies[4], auditoria[0], today + 2.days + 19.hours, 18.00 ]
].filter_map do |movie, auditorium, start_time, price|
  next if start_time.past?

  showtime = Showtime.find_or_initialize_by(movie: movie, auditorium: auditorium, start_time: start_time)
  showtime.price = price
  showtime.save!
  showtime
end

# Vorbelegte Plaetze, damit der Saalplan belegte Sitze zeigt.
# Feste Zufallssaat => bei jedem Seed dasselbe Muster.
occupancy_rates = [ 0.45, 0.20, 0.60, 0.15, 0.35, 0.05 ]

showtimes.each_with_index do |showtime, index|
  seats = showtime.auditorium.seats.ordered.to_a
  taken = seats.sample((seats.size * occupancy_rates[index % occupancy_rates.size]).round,
                       random: Random.new(1000 + index))

  taken.each do |seat|
    Booking.find_or_create_by!(showtime: showtime, seat: seat) do |booking|
      booking.user = box_office
    end
  end
end

puts "Seed abgeschlossen: #{User.count} Benutzer, #{Movie.count} Filme, " \
     "#{Auditorium.count} Saele, #{Seat.count} Sitze, #{Showtime.count} Vorstellungen, " \
     "#{Booking.count} Buchungen."
