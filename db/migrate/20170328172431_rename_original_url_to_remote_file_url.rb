class RenameOriginalUrlToRemoteFileUrl < ActiveRecord::Migration[5.0]
  def change
    rename_column :images, :original_url, :remote_file_url
  end
end
