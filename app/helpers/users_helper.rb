module UsersHelper

  def handle(user)
    truncate(user.email, length: 8, omission: "...")
  end

  # Returns the Gravatar (http://gravatar.com/) for the given user:
  def gravatar_for(user, options = { size: 60 })
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    image_tag(gravatar_url, alt: handle(user), class: "gravatar")
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

end
