class AddFileToImages < ActiveRecord::Migration[5.0]
  def change
    add_column :images, :file, :string
  end
end
