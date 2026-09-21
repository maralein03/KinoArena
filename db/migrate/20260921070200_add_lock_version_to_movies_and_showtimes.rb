class AddLockVersionToMoviesAndShowtimes < ActiveRecord::Migration[8.1]
  def change
    # NFA-2: Optimistic Locking im Admin-Bereich
    add_column :movies, :lock_version, :integer, default: 0, null: false
    add_column :showtimes, :lock_version, :integer, default: 0, null: false
  end
end
