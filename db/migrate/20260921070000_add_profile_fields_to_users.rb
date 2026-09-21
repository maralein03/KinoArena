class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    change_column_default :users, :admin, from: nil, to: false

    reversible do |dir|
      dir.up do
        execute "UPDATE users SET admin = 0 WHERE admin IS NULL"
        execute "UPDATE users SET name = email_address WHERE name IS NULL"
      end
    end

    change_column_null :users, :admin, false
  end
end
