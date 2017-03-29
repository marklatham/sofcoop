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
    process :resize_to_limit => [300, 300]
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
    model.format = 'jpg' if model.format == 'jpeg'
    model.original_filename = original_filename if original_filename.present?
    model.original_url = model.remote_file_url if model.remote_file_url.present?
  end

end
