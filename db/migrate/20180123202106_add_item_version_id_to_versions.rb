class AddItemVersionIdToVersions < ActiveRecord::Migration[5.1]
  def change
    add_column :versions, :item_version_id, :integer
  end
end
