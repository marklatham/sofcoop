class AddModToComments < ActiveRecord::Migration[5.1]
  def change
    add_column :comments, :mod, :boolean, default: false, null: false
  end
end
