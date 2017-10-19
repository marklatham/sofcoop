class RenameChannelUserAsManager < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :channels, :users
    rename_column :channels, :user_id, :manager_id
    add_foreign_key :channels, :users, column: :manager_id
  end

  def down
    remove_foreign_key :channels, :users, column: :manager_id
    rename_column :channels, :manager_id, :user_id
    add_foreign_key :channels, :users
  end
end
