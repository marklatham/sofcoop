class AddCreditToImages < ActiveRecord::Migration[5.0]
  def change
    add_column :images, :credit, :string
  end
end
