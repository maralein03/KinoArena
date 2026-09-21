class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false
      t.string :target_type
      t.integer :target_id
      t.string :description
      t.string :ip_address

      t.timestamps
    end

    add_index :activity_logs, :created_at
    add_index :activity_logs, [ :target_type, :target_id ]
  end
end
