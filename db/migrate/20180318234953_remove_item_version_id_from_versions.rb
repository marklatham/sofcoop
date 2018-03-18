class RemoveItemVersionIdFromVersions < ActiveRecord::Migration[5.1]
  def change
    remove_column :versions, :item_version_id
  end
end
