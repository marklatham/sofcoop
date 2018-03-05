class AddModStatusToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :mod_status, :boolean, default: false, null: false
  end
end
