class IdsToBigintsResource < ActiveRecord::Migration[5.1]
  def up
    change_column :roles, :resource_id, :bigint
  end

  def down
    change_column :roles, :resource_id, :integer
  end
end
