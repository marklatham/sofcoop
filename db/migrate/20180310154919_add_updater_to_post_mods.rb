class AddUpdaterToPostMods < ActiveRecord::Migration[5.1]
  def change
    add_reference :post_mods, :updater, foreign_key: { to_table: :users }
  end
end
