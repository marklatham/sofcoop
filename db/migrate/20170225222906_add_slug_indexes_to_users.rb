class AddSlugIndexesToUsers < ActiveRecord::Migration[5.0]
  def change
    add_index :users, :slug, unique: true
    add_index :users, [:username, :slug], unique: true
  end
end
