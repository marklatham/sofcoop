class RenameModAsModStatus < ActiveRecord::Migration[5.1]
  def change
    rename_column :comments, :mod, :mod_status
    rename_column :users, :mod, :mod_status
  end
end
