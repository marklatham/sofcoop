class CreatePages < ActiveRecord::Migration[5.0]
  def change
    create_table :pages do |t|
      t.belongs_to :user, foreign_key: true
      t.integer :visible
      t.string :title
      t.string :slug
      t.text :body

      t.timestamps
    end
    add_index :pages, :slug, unique: true
  end
end
