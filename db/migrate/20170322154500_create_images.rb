class CreateImages < ActiveRecord::Migration[5.0]
  def change
    create_table :images do |t|
      t.belongs_to :user, foreign_key: true
      t.string :title
      t.string :slug
      t.string :original_filename
      t.string :original_url
      t.string :format
      t.integer :width
      t.integer :height
      t.float :size
      t.text :description

      t.timestamps
    end
    add_index :images, [:user_id, :slug], unique: true
  end
end
