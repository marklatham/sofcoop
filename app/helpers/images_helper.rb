module ImagesHelper
  
  # I couldn't find a way to get these shorter URLs via carrierwave, so coded them:
  def short_url(image, version: nil)
    if version
      'https://s3-us-west-2.amazonaws.com/sofcoop/images/' +
      image.user.username + '/' + image.slug + '_' + version + '.' + image.format
    else
      'https://s3-us-west-2.amazonaws.com/sofcoop/images/' +
      image.user.username + '/' + image.slug + '.' + image.format
    end
  end
  
end
