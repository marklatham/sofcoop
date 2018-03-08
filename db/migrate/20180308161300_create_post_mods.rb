class CreatePostMods < ActiveRecord::Migration[5.1]
  def change
    create_table :post_mods do |t|
      t.references :post, index: true, foreign_key: true
      t.references :author, index: true, foreign_key: { to_table: :users }
      t.integer :visible, default: 0
      t.string :title
      t.string :slug, default: "", null: false
      t.text :body
      t.string :main_image
      t.references :channel, index: true, foreign_key: true
      t.string :category, default: "post", null: false
      t.boolean :mod_status, default: true, null: false

      t.timestamps
    end
  end
end
