module ChannelsHelper
  
  def avatar_for_channel(channel)
    if channel.avatar_url.present?
      substrings = channel.avatar_url.partition('?').first.partition('/channels/')
      avatar_url = substrings[1] + '@@' + substrings[2]
    else
      avatar_url = "https://sofcoop.s3-us-west-2.amazonaws.com/channels/default.png"
    end
    image_tag(avatar_url.to_s, alt: '@@'+channel.name)
  end

end
