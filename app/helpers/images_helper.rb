module ImagesHelper
  
  def shorten(image_url)
    substrings = image_url.partition('?').first.partition('/images/')
    substrings[1] + '@' + substrings[2]
  end
  
end
