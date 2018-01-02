class RenameVersionLastAsFirst < ActiveRecord::Migration[5.1]
  def change
    rename_column :versions, :last_created_at, :first_created_at
  end
end
