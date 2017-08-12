class ChangeColumnDefaultsOfChannels < ActiveRecord::Migration[5.1]
  def change
    change_column_default :channels, :color,    from: nil, to: '#666'
    change_column_default :channels, :color_bg, from: nil, to: '#F2F2F2'
  end
end
