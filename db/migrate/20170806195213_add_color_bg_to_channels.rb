class AddColorBgToChannels < ActiveRecord::Migration[5.1]
  def change
    add_column :channels, :color_bg, :string
  end
end
