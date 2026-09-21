class CreateSeats < ActiveRecord::Migration[8.1]
  def change
    create_table :seats do |t|
      t.references :auditorium, null: false, foreign_key: true
      t.string :row
      t.integer :number

      t.timestamps
    end
  end
end
