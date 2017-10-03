class IdsToBigintsTag < ActiveRecord::Migration[5.1]
  def up
    # tag_id is not declared as a foreign key in taggings
    change_column :tags, :id, :bigint, auto_increment: true
    change_column :taggings, :id, :bigint, auto_increment: true
    change_column :taggings, :tag_id, :bigint
  end

  def down
    change_column :taggings, :tag_id, :integer
    change_column :taggings, :id, :integer, auto_increment: true
    change_column :tags, :id, :integer, auto_increment: true
  end
end
