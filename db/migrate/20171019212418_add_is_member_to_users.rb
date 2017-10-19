class AddIsMemberToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :is_member, :boolean, default: false, null: false
  end
end
