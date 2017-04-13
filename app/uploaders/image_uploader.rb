class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include Sprockets::Rails::Helper   # do I need this?

  storage :fog

  process :store_parameters

  def store_dir
    "images/#{model.user.username}/"
  end

  def filename
    "#{model.slug}.#{model.format}"
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  version :v10 do
    process resize_to_limit: [1000, 1000]
  end

  version :v3, from_version: :v10 do
    process resize_to_limit: [300, 300]
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
    if model.remote_file_url.present?
      unless model.remote_file_url[0..17] == 'https://sofcoop.s3'
        model.original_url = model.remote_file_url
      end
    end
    # In case username gets changed and aws image file path not updated yet:
    model.aws_username = model.user.username
  end

  # Put version name on the end of filename instead of the beginning:
  
  def full_filename(for_file)
    if parent_name = super(for_file)
      extension = File.extname(parent_name)
      base_name = parent_name.chomp(extension)
      base_name = base_name[version_name.size.succ..-1] if version_name
      [base_name, version_name].compact.join(".") + extension
    end
  end

  def full_original_filename
    parent_name = super
    extension = File.extname(parent_name)
    base_name = parent_name.chomp(extension)
    base_name = base_name[version_name.size.succ..-1] if version_name
    [base_name, version_name].compact.join(".") + extension
  end

end
