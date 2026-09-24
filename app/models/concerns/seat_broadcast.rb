# Verteilt Sitzplatz-Zustaende per Turbo Stream an alle Zuschauer einer Vorstellung.
module SeatBroadcast
  module_function

  def stream_name(showtime)
    [ showtime, :seats ]
  end

  def seat_changed(showtime, seat)
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_name(showtime),
      target: "seat-cell-#{seat.id}",
      partial: "showtimes/seat",
      locals: {
        seat: seat,
        booked: showtime.bookings.exists?(seat_id: seat.id),
        hold: showtime.seat_holds.active.find_by(seat_id: seat.id)
      }
    )
  end

  def seats_changed(showtime, seats)
    seats.each { |seat| seat_changed(showtime, seat) }
  end
end
