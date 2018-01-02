class AddColumnsToVersions < ActiveRecord::Migration[5.1]
  def change
    add_column :versions, :records_merged, :integer
    add_column :versions, :last_created_at, :datetime
  end
end
