class AddIsMemberToVotes < ActiveRecord::Migration[5.1]
  def change
    add_column :votes, :is_member, :boolean, default: false, null: false
  end
end
