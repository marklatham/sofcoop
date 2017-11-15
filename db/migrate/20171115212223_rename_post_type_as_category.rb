class RenamePostTypeAsCategory < ActiveRecord::Migration[5.1]
  def change
    rename_column :posts, :type, :category
  end
end
