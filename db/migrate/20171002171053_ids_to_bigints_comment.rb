class IdsToBigintsComment < ActiveRecord::Migration[5.1]
  def up
    change_column :comments, :id, :bigint, auto_increment: true
  end

  def down
    change_column :comments, :id, :integer, auto_increment: true
  end
end
