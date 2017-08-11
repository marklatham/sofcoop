class AddDropdownIdToChannels < ActiveRecord::Migration[5.1]
  def change
    add_column :channels, :dropdown_id, :integer
  end
end
