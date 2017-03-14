module UsersHelper

  def avatar_for(user)
    if user.avatar_url.present?
      avatar_url = user.avatar_url
    else
      gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
      avatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=60"
    end
    image_tag(avatar_url, alt: '@'+user.username)
  end
  
  # Returns false if avatar_for is just the gravatar default image:
  def avatar?(user)
    if user.avatar_url.present?
      true
    else
      gravatar_check =
        "http://gravatar.com/avatar/#{Digest::MD5::hexdigest(user.email.downcase)}.png?d=404"
      uri = URI.parse(gravatar_check)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      response.code.to_i != 404
    end
  end
  
end
