class AddUniqueSeatIndexToBookings < ActiveRecord::Migration[8.1]
  def change
    # NFA-1: verhindert Doppelbuchungen desselben Sitzplatzes auf DB-Ebene
    add_index :bookings, [ :showtime_id, :seat_id ], unique: true, name: "index_bookings_on_showtime_and_seat"
  end
end
