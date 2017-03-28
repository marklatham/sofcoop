class RenameRemoteFileUrlToOriginalUrl < ActiveRecord::Migration[5.0]
  def change
    rename_column :images, :remote_file_url, :original_url
  end
end
