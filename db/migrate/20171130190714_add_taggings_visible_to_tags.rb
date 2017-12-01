class AddTaggingsVisibleToTags < ActiveRecord::Migration[5.1]
  def change
    add_column :tags, :taggings_visible, :integer, default: 0
  end
end
