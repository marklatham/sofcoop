module ApplicationHelper
  
  def visible_options
    [['Author & Admin', '0'], ['Logged-in Users', '3'], ['The World', '4']]
  end
  
  def channels_array
    array = [['None', nil]]
    for channel in Channel.all
      array << [channel.name, channel.id.to_s]
    end
    return array
  end
  
  def conditional_strftime(datetime, cutoff)
    if datetime > cutoff.months.ago
      datetime.strftime("%A, %B %e at %l:%M %P Pacific")
    else
      datetime.strftime("%B %e, %Y")
    end
  end
  
end
