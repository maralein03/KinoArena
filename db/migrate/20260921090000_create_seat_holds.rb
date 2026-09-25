class CreateSeatHolds < ActiveRecord::Migration[8.1]
  def change
    create_table :seat_holds do |t|
      t.references :showtime, null: false, foreign_key: true
      t.references :seat, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :expires_at, null: false

      t.timestamps
    end

    # FA-Opt-1: ein Sitzplatz kann pro Vorstellung nur einmal reserviert sein
    add_index :seat_holds, [ :showtime_id, :seat_id ], unique: true, name: "index_seat_holds_on_showtime_and_seat"
    add_index :seat_holds, :expires_at
  end
end
