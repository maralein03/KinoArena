class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :showtime, null: false, foreign_key: true
      t.references :seat, null: false, foreign_key: true
      t.string :qr_code_token
      t.decimal :total_price

      t.timestamps
    end
    add_index :bookings, :qr_code_token, unique: true
  end
end
