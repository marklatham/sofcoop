class ChangeUserModStatus < ActiveRecord::Migration[5.1]
  # irreversible
  def change
    change_column_default :users, :mod_status, nil
    change_column         :users, :mod_status, :boolean
    change_column_default :users, :mod_status, false
  end
end
