class CreatePages < ActiveRecord::Migration[5.0]
  def change
    create_table :pages do |t|
      t.belongs_to :user, foreign_key: true
      t.integer :visible, default: 0
      t.string :title
      t.string :slug, null: false
      t.text :body

      t.timestamps
    end
    add_index :pages, [:user_id, :slug], unique: true
  end
end
