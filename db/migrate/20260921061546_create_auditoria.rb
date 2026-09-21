class CreateAuditoria < ActiveRecord::Migration[8.1]
  def change
    create_table :auditoria do |t|
      t.string :name
      t.integer :total_seats

      t.timestamps
    end
  end
end
