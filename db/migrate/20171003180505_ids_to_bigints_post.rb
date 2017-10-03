class IdsToBigintsPost < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :comments, :posts
    change_column :posts, :id, :bigint, auto_increment: true
    change_column :comments, :post_id, :bigint
    add_foreign_key :comments, :posts
    
    change_column :channels, :dropdown_id, :bigint
    change_column :taggings, :taggable_id, :bigint
    change_column :friendly_id_slugs, :sluggable_id, :bigint
  end

  def down
    change_column :friendly_id_slugs, :sluggable_id, :bigint
    change_column :taggings, :taggable_id, :integer
    change_column :channels, :dropdown_id, :integer
    
    remove_foreign_key :comments, :posts
    change_column :comments, :post_id, :integer
    change_column :posts, :id, :integer, auto_increment: true
    add_foreign_key :comments, :posts
  end
end
