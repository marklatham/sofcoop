class AddVersionUpdatedAtToPostMods < ActiveRecord::Migration[5.1]
  def change
    add_column :post_mods, :version_updated_at, :datetime
  end
end
