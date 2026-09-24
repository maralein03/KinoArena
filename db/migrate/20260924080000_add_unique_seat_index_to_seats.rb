class AddUniqueSeatIndexToSeats < ActiveRecord::Migration[8.1]
  def change
    add_index :seats, [ :auditorium_id, :row, :number ], unique: true,
              name: "index_seats_on_auditorium_row_and_number"
  end
end
