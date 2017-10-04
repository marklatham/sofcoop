class CreateVotes < ActiveRecord::Migration[5.1]
  def change
    create_table :votes do |t|
      t.references :user, foreign_key: true
      t.references :channel, foreign_key: true
      t.float :share
      t.string :ip
      t.string :agent

      t.timestamps
    end
  end
end
