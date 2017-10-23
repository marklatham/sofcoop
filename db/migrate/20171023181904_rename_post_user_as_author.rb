class RenamePostUserAsAuthor < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :posts, :users
    rename_column :posts, :user_id, :author_id
    add_foreign_key :posts, :users, column: :author_id
  end

  def down
    remove_foreign_key :posts, :users, column: :author_id
    rename_column :posts, :author_id, :user_id
    add_foreign_key :posts, :users
  end
end
