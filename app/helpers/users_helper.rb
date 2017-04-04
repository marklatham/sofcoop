module UsersHelper

  # Returns the Gravatar (http://gravatar.com/) for the given user:
  def gravatar_for(user, options = { size: 60, class: "gravatar" })
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url, alt: '@'+user.username, class: options[:class])
  end
  
  def avatar_for(user)
    if user.avatar_url.present?
      avatar_url = user.avatar_url.partition('?').first
    else
      gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
      avatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=60"
    end
    image_tag(avatar_url.to_s, alt: '@'+user.username)
  end

  # Returns false if gravatar_for is just the default image:
  def gravatar?(user)
    gravatar_check = "http://gravatar.com/avatar/#{Digest::MD5::hexdigest(user.email.downcase)}.png?d=404"
    uri = URI.parse(gravatar_check)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    response.code.to_i != 404
  end
  
  # Returns false if avatar_for is just the gravatar default image:
  def avatar?(user)
    user.avatar_url.present? || gravatar?(user)
  end
  
end
