class AddTypeToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :type, :string, default: "post", null: false
  end
end
