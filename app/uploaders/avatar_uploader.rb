class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include Sprockets::Rails::Helper   # do I need this?

  storage :fog

  process resize_to_fill: [200, 200]

  def store_dir
    "avatars/"
  end

  def filename
    if file.extension == "jpeg"
      "#{model.username}.jpg"
    else
      "#{model.username}.#{file.extension}"
    end
  end

  def extension_white_list
    %w(jpg jpeg gif png tif tiff bmp)
  end
  
end
