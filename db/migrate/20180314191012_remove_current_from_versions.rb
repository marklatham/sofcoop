class RemoveCurrentFromVersions < ActiveRecord::Migration[5.1]
  def change
    remove_column :versions, :current
  end
end
