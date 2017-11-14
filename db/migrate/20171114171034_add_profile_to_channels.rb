class AddProfileToChannels < ActiveRecord::Migration[5.1]
  def change
    # Something like this got executed in an earler erroneous edition of this migration before it aborted:
    # add_reference :channels, :profile, index: true
    add_foreign_key :channels, :posts, column: :profile_id
  end
end
