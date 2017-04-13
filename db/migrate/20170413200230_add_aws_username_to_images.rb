class AddAwsUsernameToImages < ActiveRecord::Migration[5.0]
  def change
    add_column :images, :aws_username, :string
  end
end
