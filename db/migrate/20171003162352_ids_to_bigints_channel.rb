class IdsToBigintsChannel < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :posts, :channels
    change_column :channels, :id, :bigint, auto_increment: true
    change_column :posts, :channel_id, :bigint
    add_foreign_key :posts, :channels
  end

  def down
    remove_foreign_key :posts, :channels
    change_column :posts, :channel_id, :integer
    change_column :channels, :id, :integer, auto_increment: true
    add_foreign_key :posts, :channels
  end
end
