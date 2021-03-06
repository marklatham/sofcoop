class ChannelUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :fog

  process resize_to_fill: [200, 200]

  def store_dir
    "channels/"
  end

  def filename
    if file
      if file.extension == "jpeg"
        "#{model.slug}.jpg"
      else
        "#{model.slug}.#{file.extension}"
      end
    else
      nil
    end
  end

  def extension_white_list
    %w(jpg jpeg gif png tif tiff bmp)
  end
  
end
