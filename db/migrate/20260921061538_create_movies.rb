class CreateMovies < ActiveRecord::Migration[8.1]
  def change
    create_table :movies do |t|
      t.string :title
      t.text :description
      t.integer :duration_minutes

      t.timestamps
    end
  end
end
