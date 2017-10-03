class IdsToBigintsUser < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :channels, :users
    remove_foreign_key :comments, :users
    remove_foreign_key :images, :users
    remove_foreign_key :posts, :users
    change_column :users, :id, :bigint, auto_increment: true
    change_column :channels, :user_id, :bigint
    change_column :comments, :user_id, :bigint
    change_column :images, :user_id, :bigint
    change_column :posts, :user_id, :bigint
    add_foreign_key :channels, :users
    add_foreign_key :comments, :users
    add_foreign_key :images, :users
    add_foreign_key :posts, :users

    change_column :users_roles, :user_id, :bigint  # not declared foreign key
    change_column :taggings, :tagger_id, :bigint
    
    change_column :friendly_id_slugs, :id, :bigint, auto_increment: true
  end

  def down
    change_column :friendly_id_slugs, :id, :integer, auto_increment: true
    
    change_column :taggings, :tagger_id, :integer
    change_column :users_roles, :user_id, :integer

    remove_foreign_key :channels, :users
    remove_foreign_key :comments, :users
    remove_foreign_key :images, :users
    remove_foreign_key :posts, :users
    change_column :channels, :user_id, :integer
    change_column :comments, :user_id, :integer
    change_column :images, :user_id, :integer
    change_column :posts, :user_id, :integer
    change_column :users, :id, :integer, auto_increment: true
    add_foreign_key :channels, :users
    add_foreign_key :comments, :users
    add_foreign_key :images, :users
    add_foreign_key :posts, :users
  end
end
