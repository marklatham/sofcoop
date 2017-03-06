class RenameTablePostsPosts < ActiveRecord::Migration[5.0]
  def change
    rename_table :pages, :posts
  end
end
