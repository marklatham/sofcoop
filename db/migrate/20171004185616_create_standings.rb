class CreateStandings < ActiveRecord::Migration[5.1]
  def change
    create_table :standings do |t|
      t.references :channel, foreign_key: true
      t.integer :rank
      t.float :share
      t.float :count0
      t.float :count1
      t.datetime :tallied_at

      t.timestamps
    end
  end
end
