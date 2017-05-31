class CreateChannels < ActiveRecord::Migration[5.0]
  def change
    create_table :channels do |t|
      t.belongs_to :user, foreign_key: true
      t.string :name
      t.string :slug, null: false
      t.string :color
      t.string :avatar

      t.timestamps
    end
    add_index :channels, :slug, unique: true
  end
end
