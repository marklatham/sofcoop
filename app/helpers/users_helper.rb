module UsersHelper

  # Returns an avatar for the given user:
  def avatar_for(user, options = { size: 60, class: "gravatar" })
    if user.avatar_url.present?
      if options[:size] < 40
        avatar_url = user.avatar_url(:square32)
      elsif options[:size] < 54
        avatar_url = user.avatar_url(:square48)
      else
        avatar_url = user.avatar_url(:square60)
      end
    else
      gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
      size = options[:size]
      avatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}?s=#{size}"
    end
    image_tag(avatar_url, alt: '@'+user.username, class: options[:class])
  end
  
  # Returns false if avatar_for is just the gravatar default image:
  def avatar?(user)
    if user.avatar_url.present?
      true
    else
      gravatar_check = "http://gravatar.com/avatar/#{Digest::MD5::hexdigest(user.email.downcase)}.png?d=404"
      uri = URI.parse(gravatar_check)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      response.code.to_i != 404
    end
  end
  
end
