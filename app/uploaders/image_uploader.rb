class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include Sprockets::Rails::Helper   # do I need this?

  storage :file
  #storage :fog

  process :store_parameters

  def store_dir
    "images/#{model.user.username}/"
  end

  # Thumbnail version of image uploaded:
  version :thumb do
    process :resize_to_limit => [300, 3000]
  end   

  # Allow images only in these formats:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    "#{model.slug}.#{model.format}"
  end

  private

  def store_parameters
    image = ::MiniMagick::Image::read(File.binread(@file.file))
    model.width  = image[:width]
    model.height = image[:height]
    model.size   = image[:size]
    model.format = image[:format].downcase
    model.original_filename = original_filename if original_filename.present?
  end

end
