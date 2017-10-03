class IdsToBigintsRole < ActiveRecord::Migration[5.1]
  def up
    change_column :roles, :id, :bigint, auto_increment: true
    change_column :users_roles, :role_id, :bigint
  end

  def down
    change_column :users_roles, :role_id, :integer
    change_column :roles, :id, :integer, auto_increment: true
  end
end
