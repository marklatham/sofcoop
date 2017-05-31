class AddChannelToPosts < ActiveRecord::Migration[5.0]
  def change
    add_reference :posts, :channel, index: true, foreign_key: true, optional: true
  end
end
