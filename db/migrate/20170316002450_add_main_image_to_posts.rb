class AddMainImageToPosts < ActiveRecord::Migration[5.0]
  def change
    add_column :posts, :main_image, :string
  end
end
