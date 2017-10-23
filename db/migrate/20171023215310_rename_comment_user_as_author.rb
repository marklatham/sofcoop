class RenameCommentUserAsAuthor < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :comments, :users
    rename_column :comments, :user_id, :author_id
    add_foreign_key :comments, :users, column: :author_id
  end

  def down
    remove_foreign_key :comments, :users, column: :author_id
    rename_column :comments, :author_id, :user_id
    add_foreign_key :comments, :users
  end
end
