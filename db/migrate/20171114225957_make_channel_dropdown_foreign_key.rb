class MakeChannelDropdownForeignKey < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key :channels, :posts, column: :dropdown_id
    add_index :channels, :dropdown_id
  end
end
