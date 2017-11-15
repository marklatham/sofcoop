class AddProfileToUsers < ActiveRecord::Migration[5.1]
  def change
    add_reference :users, :profile
    add_foreign_key :users, :posts, column: :profile_id
  end
end
