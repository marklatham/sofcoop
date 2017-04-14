class RemoveAwsUsernameFromImages < ActiveRecord::Migration[5.0]
  def change
    remove_column :images, :aws_username
  end
end
