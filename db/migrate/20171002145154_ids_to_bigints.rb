class IdsToBigints < ActiveRecord::Migration[5.1]
  def up
    change_column :images, :id, :bigint, auto_increment: true
  end

  def down
    change_column :images, :id, :integer, auto_increment: true
  end
end
