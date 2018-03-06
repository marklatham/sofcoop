class AddModFieldsToVersions < ActiveRecord::Migration[5.1]
  def change
    add_column :versions, :mod_status, :boolean, default: false, null: false
    add_column :versions, :current, :boolean, default: false, null: false
  end
end
